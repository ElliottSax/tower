"""Setup for quant-shared package."""

from setuptools import setup, find_packages

setup(
    name="quant-shared",
    version="1.0.0",
    description="Shared models and utilities for Quant Analytics",
    author="Elliott",
    packages=find_packages(),
    install_requires=[
        "sqlalchemy>=2.0.31",
        "pydantic>=2.8.2",
        "asyncpg>=0.29.0",
        "psycopg2-binary>=2.9.9",
    ],
    python_requires=">=3.11",
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "Programming Language :: Python :: 3.11",
    ],
)
