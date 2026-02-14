"""
LLM Service - Unified interface for DeepSeek, Hugging Face, and local models

This service abstracts LLM calls to use the cheapest/best option for each task:
- DeepSeek: Complex reasoning, pattern analysis ($0.14-0.28 per 1M tokens)
- Hugging Face: Text generation, embeddings (FREE tier available)
- Local models: Simple tasks, zero cost after download

Cost comparison (per 1M tokens):
- GPT-4: $30-60
- Claude 3.5 Sonnet: $15-75
- DeepSeek-V3: $0.14-0.28  ← 100-200x cheaper!
- Hugging Face: FREE (rate limited) or $9/month unlimited
- Local models: FREE (one-time download)
"""

import os
from typing import Dict, List, Optional, Any, Literal
from enum import Enum
import logging
import json

logger = logging.getLogger(__name__)


class ModelProvider(str, Enum):
    """Available model providers."""
    DEEPSEEK = "deepseek"
    HUGGINGFACE = "huggingface"
    LOCAL = "local"
    OLLAMA = "ollama"  # For local hosting


class TaskType(str, Enum):
    """Types of tasks with recommended models."""
    COMPLEX_REASONING = "complex_reasoning"  # DeepSeek
    TEXT_GENERATION = "text_generation"      # HuggingFace/Local
    SUMMARIZATION = "summarization"          # HuggingFace/Local
    CLASSIFICATION = "classification"        # HuggingFace/Local
    EMBEDDINGS = "embeddings"                # HuggingFace/Local
    CODE_GENERATION = "code_generation"      # DeepSeek


class LLMService:
    """
    Unified LLM service that routes tasks to the most cost-effective provider.

    Usage:
        llm = LLMService()

        # Complex pattern analysis
        analysis = llm.generate(
            prompt="Analyze this trading pattern...",
            task_type=TaskType.COMPLEX_REASONING,
            prefer_provider=ModelProvider.DEEPSEEK
        )

        # Simple description
        description = llm.generate(
            prompt="Summarize this discovery...",
            task_type=TaskType.SUMMARIZATION,
            prefer_provider=ModelProvider.LOCAL  # Use free local model
        )
    """

    def __init__(
        self,
        deepseek_api_key: Optional[str] = None,
        huggingface_api_key: Optional[str] = None,
        default_provider: ModelProvider = ModelProvider.DEEPSEEK,
        enable_local_fallback: bool = True,
    ):
        """
        Initialize LLM service.

        Args:
            deepseek_api_key: DeepSeek API key (or set DEEPSEEK_API_KEY env var)
            huggingface_api_key: HuggingFace API key (or set HF_API_KEY env var)
            default_provider: Default provider to use
            enable_local_fallback: Fall back to local models if API fails
        """
        self.deepseek_api_key = deepseek_api_key or os.getenv("DEEPSEEK_API_KEY")
        self.huggingface_api_key = huggingface_api_key or os.getenv("HF_API_KEY")
        self.default_provider = default_provider
        self.enable_local_fallback = enable_local_fallback

        # Initialize clients
        self._init_deepseek()
        self._init_huggingface()
        self._init_local()

        logger.info(f"LLM Service initialized with provider: {default_provider}")

    def _init_deepseek(self):
        """Initialize DeepSeek client."""
        if self.deepseek_api_key:
            try:
                from openai import OpenAI

                self.deepseek_client = OpenAI(
                    api_key=self.deepseek_api_key,
                    base_url="https://api.deepseek.com"
                )
                logger.info("DeepSeek client initialized")
            except ImportError:
                logger.warning("OpenAI SDK not installed. Install with: pip install openai")
                self.deepseek_client = None
        else:
            logger.warning("No DeepSeek API key found")
            self.deepseek_client = None

    def _init_huggingface(self):
        """Initialize Hugging Face client."""
        try:
            from huggingface_hub import InferenceClient

            self.hf_client = InferenceClient(
                token=self.huggingface_api_key
            )
            logger.info("Hugging Face client initialized")
        except ImportError:
            logger.warning("huggingface_hub not installed. Install with: pip install huggingface_hub")
            self.hf_client = None

    def _init_local(self):
        """Initialize local models."""
        try:
            from transformers import pipeline

            # Load small, fast local models
            self.local_summarizer = pipeline(
                "summarization",
                model="facebook/bart-large-cnn",
                device=-1  # CPU
            )
            self.local_generator = pipeline(
                "text-generation",
                model="gpt2",  # Small, fast
                device=-1
            )
            logger.info("Local models initialized")
        except ImportError:
            logger.warning("transformers not installed. Install with: pip install transformers")
            self.local_summarizer = None
            self.local_generator = None

    def generate(
        self,
        prompt: str,
        task_type: TaskType = TaskType.TEXT_GENERATION,
        prefer_provider: Optional[ModelProvider] = None,
        max_tokens: int = 1000,
        temperature: float = 0.7,
        **kwargs
    ) -> str:
        """
        Generate text using the most appropriate model.

        Args:
            prompt: Input prompt
            task_type: Type of task (affects model selection)
            prefer_provider: Preferred provider (or None for auto-select)
            max_tokens: Maximum tokens to generate
            temperature: Sampling temperature
            **kwargs: Additional provider-specific arguments

        Returns:
            Generated text
        """
        provider = prefer_provider or self._select_provider(task_type)

        try:
            if provider == ModelProvider.DEEPSEEK:
                return self._generate_deepseek(prompt, max_tokens, temperature, **kwargs)
            elif provider == ModelProvider.HUGGINGFACE:
                return self._generate_huggingface(prompt, max_tokens, temperature, **kwargs)
            elif provider == ModelProvider.LOCAL:
                return self._generate_local(prompt, task_type, max_tokens, **kwargs)
            else:
                raise ValueError(f"Unknown provider: {provider}")

        except Exception as e:
            logger.error(f"Generation failed with {provider}: {e}")

            if self.enable_local_fallback and provider != ModelProvider.LOCAL:
                logger.info("Falling back to local models")
                return self._generate_local(prompt, task_type, max_tokens, **kwargs)
            else:
                raise

    def _select_provider(self, task_type: TaskType) -> ModelProvider:
        """Auto-select best provider for task type."""

        # Task-specific recommendations
        if task_type == TaskType.COMPLEX_REASONING:
            # DeepSeek excels at reasoning
            return ModelProvider.DEEPSEEK if self.deepseek_client else ModelProvider.LOCAL

        elif task_type == TaskType.EMBEDDINGS:
            # HuggingFace has great embedding models
            return ModelProvider.HUGGINGFACE if self.hf_client else ModelProvider.LOCAL

        elif task_type in [TaskType.SUMMARIZATION, TaskType.CLASSIFICATION]:
            # HuggingFace or local work well for these
            return ModelProvider.HUGGINGFACE if self.hf_client else ModelProvider.LOCAL

        else:
            # Default to configured provider
            return self.default_provider

    def _generate_deepseek(
        self,
        prompt: str,
        max_tokens: int,
        temperature: float,
        **kwargs
    ) -> str:
        """Generate using DeepSeek API."""
        if not self.deepseek_client:
            raise RuntimeError("DeepSeek client not initialized")

        response = self.deepseek_client.chat.completions.create(
            model="deepseek-chat",  # or "deepseek-coder" for code tasks
            messages=[
                {"role": "system", "content": "You are a quantitative analyst specializing in pattern recognition."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=max_tokens,
            temperature=temperature,
            **kwargs
        )

        return response.choices[0].message.content

    def _generate_huggingface(
        self,
        prompt: str,
        max_tokens: int,
        temperature: float,
        model: str = "mistralai/Mistral-7B-Instruct-v0.2",
        **kwargs
    ) -> str:
        """Generate using Hugging Face Inference API."""
        if not self.hf_client:
            raise RuntimeError("Hugging Face client not initialized")

        response = self.hf_client.text_generation(
            prompt,
            model=model,
            max_new_tokens=max_tokens,
            temperature=temperature,
            **kwargs
        )

        return response

    def _generate_local(
        self,
        prompt: str,
        task_type: TaskType,
        max_tokens: int,
        **kwargs
    ) -> str:
        """Generate using local models."""
        if task_type == TaskType.SUMMARIZATION and self.local_summarizer:
            result = self.local_summarizer(
                prompt,
                max_length=max_tokens,
                min_length=30,
                do_sample=False
            )
            return result[0]['summary_text']

        elif self.local_generator:
            result = self.local_generator(
                prompt,
                max_length=max_tokens,
                num_return_sequences=1,
                **kwargs
            )
            return result[0]['generated_text']

        else:
            raise RuntimeError("No local models available")

    def analyze_pattern(
        self,
        pattern_data: Dict[str, Any],
        politician_name: str,
        pattern_type: str
    ) -> str:
        """
        Analyze a pattern and generate natural language description.

        Uses DeepSeek for complex reasoning about patterns.
        """
        prompt = f"""Analyze this trading pattern discovered in {politician_name}'s trading history:

Pattern Type: {pattern_type}
Data: {json.dumps(pattern_data, indent=2)}

Provide:
1. A clear, non-technical description (2-3 sentences)
2. Statistical significance assessment
3. Potential implications or concerns
4. Recommended actions

Be objective and data-driven. Avoid speculation."""

        return self.generate(
            prompt=prompt,
            task_type=TaskType.COMPLEX_REASONING,
            prefer_provider=ModelProvider.DEEPSEEK,
            max_tokens=500,
            temperature=0.3  # Lower for more factual
        )

    def explain_anomaly(
        self,
        anomaly_evidence: Dict[str, Any],
        politician_name: str
    ) -> str:
        """
        Explain an anomaly in plain English.

        Uses DeepSeek for reasoning about what makes this unusual.
        """
        prompt = f"""An anomaly was detected in {politician_name}'s trading:

Evidence: {json.dumps(anomaly_evidence, indent=2)}

Explain in plain English:
1. What makes this unusual (2-3 sentences)
2. How severe is this (scale 1-10 with justification)
3. What further investigation is needed
4. Is this likely a false positive? Why or why not?

Be thorough but concise. Focus on facts from the evidence."""

        return self.generate(
            prompt=prompt,
            task_type=TaskType.COMPLEX_REASONING,
            prefer_provider=ModelProvider.DEEPSEEK,
            max_tokens=600,
            temperature=0.2
        )

    def generate_summary(
        self,
        discoveries: List[Dict[str, Any]]
    ) -> str:
        """
        Generate executive summary of multiple discoveries.

        Uses cheaper HuggingFace/local models for summarization.
        """
        # Format discoveries as text
        text = "Recent Pattern Discoveries:\n\n"
        for disc in discoveries[:10]:  # Top 10
            text += f"- {disc['politician_name']}: {disc['pattern_type']} "
            text += f"(strength: {disc['strength']:.2f})\n"

        text += "\nSummarize the key findings and notable patterns."

        return self.generate(
            prompt=text,
            task_type=TaskType.SUMMARIZATION,
            prefer_provider=ModelProvider.HUGGINGFACE,
            max_tokens=300
        )

    def get_embeddings(
        self,
        texts: List[str],
        model: str = "sentence-transformers/all-MiniLM-L6-v2"
    ) -> List[List[float]]:
        """
        Get embeddings for similarity search.

        Uses HuggingFace embedding models (free and fast).
        """
        if not self.hf_client:
            raise RuntimeError("Hugging Face client not initialized")

        embeddings = []
        for text in texts:
            embedding = self.hf_client.feature_extraction(
                text,
                model=model
            )
            embeddings.append(embedding)

        return embeddings

    def estimate_cost(
        self,
        prompt: str,
        completion_tokens: int,
        provider: ModelProvider = ModelProvider.DEEPSEEK
    ) -> float:
        """
        Estimate cost in USD for a generation.

        Pricing (per 1M tokens):
        - DeepSeek-V3: $0.14 input, $0.28 output
        - GPT-4: $30 input, $60 output (for comparison)
        - HuggingFace: $0 (free tier) or $9/month unlimited
        - Local: $0
        """
        input_tokens = len(prompt.split()) * 1.3  # Rough estimate

        if provider == ModelProvider.DEEPSEEK:
            input_cost = (input_tokens / 1_000_000) * 0.14
            output_cost = (completion_tokens / 1_000_000) * 0.28
            return input_cost + output_cost

        elif provider == ModelProvider.HUGGINGFACE:
            return 0.0  # Free tier

        elif provider == ModelProvider.LOCAL:
            return 0.0

        else:
            return 0.0


# ============================================================================
# Convenience Functions
# ============================================================================

# Global instance
_llm_service: Optional[LLMService] = None


def get_llm_service() -> LLMService:
    """Get or create global LLM service instance."""
    global _llm_service

    if _llm_service is None:
        _llm_service = LLMService()

    return _llm_service


def analyze_discovery_with_llm(
    discovery: Dict[str, Any]
) -> str:
    """
    Analyze a discovery and generate description using LLM.

    This replaces hardcoded descriptions with AI-generated ones.
    """
    llm = get_llm_service()

    return llm.analyze_pattern(
        pattern_data={
            'strength': discovery.get('strength'),
            'confidence': discovery.get('confidence'),
            'parameters': discovery.get('parameters'),
            'metadata': discovery.get('metadata'),
        },
        politician_name=discovery.get('politician_name', 'Unknown'),
        pattern_type=discovery.get('pattern_type', 'unknown')
    )


def explain_anomaly_with_llm(
    anomaly: Dict[str, Any]
) -> str:
    """Explain an anomaly using LLM."""
    llm = get_llm_service()

    return llm.explain_anomaly(
        anomaly_evidence=anomaly.get('evidence', {}),
        politician_name=anomaly.get('politician_name', 'Unknown')
    )
