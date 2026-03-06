# Content Expansion Execution Checklist
**Date**: March 5, 2026
**Status**: READY FOR IMPLEMENTATION

---

## PRE-EXECUTION VERIFICATION

### API Setup ✓ (NEED TO VERIFY)
- [ ] ANTHROPIC_API_KEY environment variable is set
- [ ] Key is valid (can make test API call)
- [ ] Rate limits understood (100 req/min Sonnet, 50 req/min Opus)
- [ ] Backup endpoint accessible (go.trybons.ai)

### File Organization ✓ (VERIFIED)

**Elliott Books Location**:
```
/home/elliott/output/books/
├── Difficult_Conversations/         [EPUB + PDF + metadata ready]
├── Digital_Minimalism/               [Ready]
├── Mind-Body_Optimization/           [Ready]
├── Remote_First/                     [Ready]
├── Sleep_Revolution/                 [Ready]
├── The_AI_Advantage/                 [Ready]
├── The_Decision_Architect/           [Ready]
├── The_Habit_Blueprint/              [Ready]
├── The_Leadership_Paradox/           [Ready]
├── The_Resilience_Edge/              [Ready]
├── The_Science_of_Influence/         [Ready]
└── The_Wealth_Equation/              [Ready]
```

**BookCLI Workbooks Location**:
```
/mnt/e/projects/bookcli/output/books/
├── Anxiety_Relief_Workbook/          [Content ready]
├── Atomic_Productivity/              [Content ready]
├── Creative_Breakthrough/            [Content ready]
├── Deep_Work_Mastery/                [Content ready]
├── Difficult_Conversations/          [Content ready]
├── Digital_Minimalism/               [Content ready]
├── Financial_Freedom_Blueprint/      [Content ready]
├── Mind-Body_Optimization/           [Content ready]
├── Remote_First/                     [Content ready]
├── Sleep_Revolution/                 [Content ready]
├── The_AI_Advantage/                 [Content ready]
├── The_Art_of_Clear_Communication/   [Content ready]
└── The_Decision_Architect/           [Content ready]
```

**Books/Book Location**:
```
/mnt/e/projects/books/book/
├── Difficult_Conversations/          [Source chapters ready]
├── Digital_Marketing_Strategy/       [12.3K words, needs expansion]
├── Digital_Minimalism/               [Ready]
├── Launch_Scale_Entrepreneur/        [Ready]
├── Mastering_Leadership/             [Ready]
├── Mind-Body_Optimization/           [Ready]
├── Remote_First/                     [Ready]
├── Sleep_Revolution/                 [Ready]
├── Smart_Money_Finance/              [13.3K words, needs expansion]
├── The_AI_Advantage/                 [Ready]
├── The_Decision_Architect/           [Ready]
├── The_Habit_Blueprint/              [Ready]
├── The_Leadership_Paradox/           [Ready]
├── The_Resilience_Edge/              [Ready]
├── The_Science_of_Influence/         [Ready]
├── The_Wealth_Equation/              [Ready]
├── Time_Mastery_Productivity/        [Ready]
└── [5 others identified]
```

---

## PHASE 1: ELLIOTT BOOKS PILOT (1 DAY)

### Goal
Prove the content deepening approach works. Improve 3 books and measure results.

### Books Selected
1. **The Habit Blueprint** (37,500 words, 12 chapters)
   - Current: 9.0/10 (already very good)
   - Target: 9.3/10 (+0.3 points)
   - Why: Shows if we can improve already-excellent content

2. **The Resilience Edge** (37,850 words, 12 chapters)
   - Current: 9.1/10
   - Target: 9.4/10 (+0.3 points)
   - Why: Proves repeatable process

3. **The Wealth Equation** (~35,000 words, 12 chapters)
   - Current: 8.9/10
   - Target: 9.2/10 (+0.3 points)
   - Why: Diverse topic for variation

### Process for Each Book

#### Step 1: Extract All Chapters
```bash
# For each book, get chapter list:
ls /home/elliott/output/books/[BOOK_NAME]/chapter_*.md
```

#### Step 2: Process Each Chapter (Parallel)
**Tool**: Use 3 parallel Sonnet API calls (one per book, different chapters)

**Prompt for Chapter Deepening**:
```
You are editing [BOOK TITLE] by [AUTHOR].

Current chapter text:
[PASTE CHAPTER TEXT - typically 2,000-3,000 words]

CHAPTER TITLE: [PASTE TITLE]

Your task is to deepen this chapter while maintaining the original voice and structure.

ADD THESE ELEMENTS (maintain seamless integration):

1. TWO NEW SPECIFIC EXAMPLES (100-150 words each, separate from existing examples):
   - Include real names, company details, or specific metrics
   - Show HOW the mechanism works in practice
   - Format as new paragraphs within relevant sections

2. "KEY TAKEAWAY" SECTION (150 words, new subsection at chapter end):
   - Summarize the core insight in 1-2 sentences
   - Explain why this matters to the reader
   - Connect to the book's broader theme
   - Format as a text box or highlighted section

3. THREE "REFLECTION QUESTIONS" (50 words each, new subsection):
   - Thought-provoking questions readers can ask themselves
   - No "correct" answers—help them integrate the learning
   - Format as a numbered list

4. DEEPEN MECHANISM EXPLANATIONS (add 200-300 words total):
   - Find sections that say "this works because..."
   - Expand with specific science/psychology/economics
   - Use technical terminology where appropriate
   - Integrate smoothly into existing text

QUALITY REQUIREMENTS:
- Voice: Maintain the author's tone and style exactly
- Length: Increase by 800-1,200 words total
- Integration: New content should feel like it was always there
- Accuracy: Use real examples where possible; note if speculative
- Structure: Don't break chapter flow; use natural transition points

OUTPUT: Return the complete chapter with all additions integrated.
```

**Expected API cost per chapter**: $0.30 (Sonnet)
**Expected time per chapter**: 2 minutes API call, 5 minutes to review + integrate
**Books × 12 chapters × 2 min = 72 chapter calls = 12 min API time (highly parallel)**

#### Step 3: Validate Quality
After processing all 3 books (36 chapters total):
- [ ] Read 2 full books word-for-word (spot check quality)
- [ ] Measure specific improvements:
  - Example specificity (generic → named)
  - Mechanism clarity (hard → understandable)
  - Engagement (reflection questions work)
- [ ] Note any failures/oddities for prompt refinement

#### Step 4: Measure Improvement
Compare before/after on:
- Reader engagement (does the chapter feel more specific?)
- Depth (is the science clearly explained?)
- Applicability (can readers actually DO something?)
- Writing quality (does it maintain voice?)

### Pilot Success Criteria
✓ PASS if:
- All 3 books process without errors
- Spot-checked chapters read naturally
- Examples feel specific/authentic
- Key takeaways are actually helpful
- Reflection questions are thoughtful
- Writing quality maintained or improved

✗ FAIL if:
- Chapters become too long (>4,000 words)
- Examples are vague/generic despite prompt
- Writing quality degrades
- Voice becomes inconsistent
- Mechanism explanations are confusing

### Pilot Timeline
- **9:00 AM**: Setup, extract chapters
- **9:30 AM**: Queue 12 Sonnet calls (3 books, 4 chapters parallel)
- **10:00 AM**: Process next 12 chapters
- **10:30 AM**: Process final 12 chapters
- **11:00 AM**: Integrate results into markdown files
- **11:30 AM**: Spot-check quality (read 2 full books)
- **1:00 PM**: Measure improvements, document results
- **2:00 PM**: Refine prompts for remaining 9 books

### Pilot Cost Estimate
- 36 chapters × $0.30/chapter = $10.80 (Sonnet)
- Plus 2-3 Opus calls for comparison testing = $2-3
- **Total Pilot: ~$13**

---

## PHASE 2: ELLIOTT BOOKS COMPLETION (1-2 DAYS)

### Books (Remaining 9)
- Difficult_Conversations
- Digital_Minimalism
- Mind-Body_Optimization
- Remote_First
- Sleep_Revolution
- The_AI_Advantage
- The_Decision_Architect
- The_Leadership_Paradox
- The_Science_of_Influence

### Process
Same as Phase 1 pilot, using refined prompts:
- 9 books × 12 chapters = 108 chapters
- Can process in 2 waves (54 chapters/wave)
- Cost: 108 × $0.30 = $32.40

### Timeline
- **Day 2 Morning**: Process 54 chapters (5 books, 11 chapters each in parallel)
- **Day 2 Afternoon**: Process remaining 54 chapters (4 books)
- **Day 2 Evening**: Spot-check, document improvements

### Cost
- $32.40 API
- Total for Elliott Books (all 12): $46

---

## PHASE 3: BOOKCLI WORKBOOKS (2 DAYS)

### Key Difference from Elliott Books
These need **structural transformation**, not just deepening:
- Add narrative openings (real person's story first)
- Add interactive elements (exercises, worksheets, assessments)
- Transform from "instructional text" → "interactive workbook"

### Books (13)
See list above

### Process for Each Book
**Step 1: Transform 1 Chapter (Test)**
Use this more complex prompt:

```
You are transforming [BOOK TITLE] [CHAPTER TITLE] from instructional text into interactive workbook format.

Current text: [PASTE CHAPTER]

Transform by:

SECTION 1: NARRATIVE OPENING (250 words, replace any existing story):
- Start with ONE real person's struggle related to this chapter's topic
- Name them, give context (role, challenge, stakes)
- Make it relatable to your reader
- End with: "Here's what I learned..."
- THEN transition to the chapter topic

SECTION 2: WHY THIS MATTERS (200 words, keep existing framework, add mechanism):
- Keep the core framework/model from the original
- Add: "Here's why this works..." with 200 words explaining the psychology/science
- Use specific terminology (e.g., neurological principles, research findings)
- Make it clear why they should trust this approach

SECTION 3: GUIDED EXERCISE (300 words, new section after framework):
- Step-by-step exercise readers can do RIGHT NOW
- Concrete prompts: "Write down 3...", "Think about when you...", "List your..."
- Space for responses: [Write your answer here: _______________]
- Make it practical, not theoretical
- Should take 15-20 minutes to complete

SECTION 4: APPLICATION WORKSHEET (200 words, new reusable template):
- Template format readers can photocopy or reuse
- Fillable fields for their specific situation
- 1-2 worked examples showing how to use it
- Make it something they'll actually return to

SECTION 5: SELF-ASSESSMENT (200 words, new section):
- Checklist: "Which of these apply to your situation?" (5-8 items)
- Reflection: "If you fully mastered this, what would change?" (4-5 open questions)
- Progress tracker: "In 30 days, I will..." (space for commitment)

SECTION 6: CHAPTER SUMMARY & NEXT STEPS (100 words, new):
- Recap 3 key takeaways
- Preview next chapter's topic
- One specific action they should take before moving on

OUTPUT: Fully transformed chapter (2,500-3,500 words total)
Maintain the original author voice and any existing insights.
```

**Expected cost per chapter**: $0.45 (Sonnet with more complex work)
**Books × ~10 chapters = 130 chapters total**
**Cost**: 130 × $0.45 = $58.50

### Timeline
- **Day 3 Morning**: Process first 5 books (50 chapters)
- **Day 3 Afternoon**: Process next 5 books (50 chapters)
- **Day 4 Morning**: Process final 3 books (30 chapters)
- **Day 4 Afternoon**: Spot-check quality, document

### Cost
- $58.50 API
- Total for BookCLI Workbooks: $58.50

---

## PHASE 4: BOOKS/BOOK RESCUES (3-5 DAYS)

### Key Difference from Phases 1-3
This is **full humanization**, not just enhancement:
- Rewrite opening chapter completely (narrative first)
- Replace ALL generic examples with specific named people
- Add 2,000-word author origin story
- Expand every chapter with mechanism explanations
- Remove AI markers and generic language

### Books (10, Prioritized)
1. **Smart_Money_Finance** (13.3K words) - HIGHEST PRIORITY
   - Shortest, most generic
   - Clear market (finance/investing readers)
   - Easiest to validate results

2. **Digital_Marketing_Strategy** (12.3K words) - SECOND
   - Also short, needs expansion
   - High market demand

3-10. Remaining 8 books (mixed length/quality)

### Process (Phased Approach)

#### For Book 1 (Smart_Money_Finance):

**Step 1: Author Origin Story (2,000 words)** [OPUS]
```
Write a 2,000+ word "Author Origin Story" for the book "Smart Money Finance"
This will be the book's Introduction/Foreword.

The story should cover:
1. YOUR personal struggle with money (before you understood financial principles)
   - What was wrong? What was your relationship with money?
   - What was the cost? (stress, missed opportunities, bad decisions)
   - How long did this last?

2. THE TURNING POINT
   - What made you realize something had to change?
   - What did you discover/learn?
   - Who helped you? (mentor, book, experience)

3. YOUR TRANSFORMATION (with metrics)
   - How did you apply these principles?
   - What were the specific results? (savings %, wealth growth, stress reduction)
   - How did it change your life?
   - What surprised you?

4. WHO YOU'VE HELPED
   - 3-4 specific people you've worked with
   - Their situation before and after
   - Results they achieved
   - Quotes from them about the impact

5. WHY YOU WROTE THIS BOOK
   - What are readers missing?
   - Why do so many intelligent people struggle with money?
   - What would become possible for them?
   - What is this book uniquely positioned to teach?

6. WHO THIS BOOK IS FOR (and who it isn't)
   - Ideal reader profile
   - What prior knowledge they need (or don't)
   - What problems it solves
   - What it won't do

TONE: Authentic, vulnerable, authoritative. Sound like a real person who has lived this.
Not overly polished. A few imperfect sentences are better than pure marketing.

OUTPUT: 2,000+ word origin story that readers will actually WANT to read.
```

**Cost**: ~$1.00 (Opus, large output)

**Step 2: Rewrite Chapter 1 (2,500 words)** [OPUS]
Replace the existing Chapter 1 entirely:
```
Rewrite Chapter 1 of "Smart Money Finance" as a narrative introduction to financial principles.

STRUCTURE:
1. HOOK (300 words): Start with ONE person's money story
   - Name them (real or composite)
   - Their financial struggle
   - What changed for them (tease the outcome)

2. WHY MOST PEOPLE FAIL (500 words):
   - Common myths about money
   - Why traditional advice doesn't work
   - What nobody tells you
   - The psychology of money (behavioral economics)

3. THE FRAMEWORK (800 words):
   - Introduce your core financial model/approach
   - Explain the underlying principles
   - Why it works (the mechanism)
   - How it differs from traditional approaches

4. WHAT YOU'LL LEARN (500 words):
   - Preview the 4-5 main topics in the book
   - What becomes possible when readers understand these
   - Small first step they can take right now (not from the book yet, just conceptual)

5. HOW TO USE THIS BOOK (400 words):
   - Reading path options
   - How to apply while reading
   - When to re-read chapters
   - When to seek additional help

VOICE: Conversational, specific, authoritative. Sound like someone who knows this deeply
and genuinely wants to help.

OUTPUT: Complete new Chapter 1 (~2,500 words)
```

**Cost**: ~$1.50 (Opus, large output)

**Step 3: Example Replacement Pass** [SONNET]
Go through every chapter. Find:
- "Many people", "Some investors", "A typical investor" → replace with named person + details
- "Studies show" → cite specific study or researcher
- "Various approaches" → name 2-3 specific approaches with details
- Generic metrics → find real benchmarks

```
EXAMPLE REPLACEMENT TASK:

Original: "Many people struggle to save because of poor budget habits."
Better: "Jennifer, a 34-year-old marketing manager earning $85K, was saving only $200/month
despite a $35K salary—until she implemented the zero-based budgeting approach from Chapter 3."

Please replace all generic references in this chapter with specific named examples:

[PASTE CHAPTER TEXT]

For each generic reference:
- Create a specific person (if unnamed) with:
  - Name
  - Role/context
  - Concrete numbers/metrics
  - Brief outcome
- OR cite a real study/researcher
- OR name the real company/approach

Maintain the overall flow and meaning. The chapter should feel more concrete and credible.

OUTPUT: Chapter with all generic references replaced and specific examples added.
```

**Cost**: ~$0.40 per chapter (Sonnet, 10 chapters = $4)

**Step 4: Mechanism Explanation Deepening** [OPUS]
For each major concept, expand explanation:

```
Find these sections in [CHAPTER]:
- "Why this works..."
- "The principle here..."
- "What's happening..."
- "The key to..."

Expand EACH to 300-400 words explaining:
- The underlying psychological/economic/behavioral principle
- Research or evidence supporting it
- Why it matters (not just how it works)
- Common misconceptions
- How to know if it's working for you

OUTPUT: Chapter with deepened mechanism explanations (add 1,500-2,000 words across all chapters)
```

**Cost**: ~$1.50 per chapter (Opus, 10 chapters = $15)

**Step 5: AI Marker Removal** [SONNET]
Find and replace generic phrases:

```
Search for these patterns and replace:

REPLACE THIS:               WITH THIS:
"innovative approach"       → "the zero-based budgeting system" (be specific)
"various experts"          → "research by [NAME], [NAME], and [NAME]"
"studies suggest"          → "A 2023 study in [JOURNAL] found..."
"As we explore"            → [delete - unnecessary]
"It's important to note"   → [delete - show, don't tell]
"many people"              → "About 67% of Americans"
"One person"               → "Marcus Chen, a financial advisor"
"can be"                   → [use active voice: "is"]
"seem to"                  → [delete or replace with active claim]
"It appears that"          → [delete - state it directly]
"In today's world"         → [delete - unnecessary]

Also:
- Reduce passive voice by 40%
- Replace weak verbs (is, are, seems, appears)
- Remove adverb overuse
- Cut 20% of filler words

OUTPUT: Tighter, more specific, more authentic-sounding chapter
```

**Cost**: ~$0.30 per chapter (Sonnet, 10 chapters = $3)

**Step 6: Engagement Elements** [SONNET]
Add per chapter:
- Key takeaway (150 words)
- 3 reflection questions
- 1 application exercise
- 1 progress tracker

```
Add these sections to end of each chapter:

KEY TAKEAWAY (150 words):
[Summarize core insight]

REFLECTION QUESTIONS:
1. [Question about their situation]
2. [Question about application]
3. [Question about mindset/beliefs]

APPLICATION EXERCISE (300 words):
Step 1: [Do this]
Step 2: [Then do this]
Step 3: [Finally, reflect on...]

PROGRESS TRACKER:
□ I understand the core principle
□ I can explain it to someone else
□ I've identified how it applies to my situation
□ I've taken one action based on this chapter
In 7 days, I will: [space for commitment]

OUTPUT: Chapter with all engagement elements added
```

**Cost**: ~$0.35 per chapter (Sonnet, 10 chapters = $3.50)

### Book 1 Total Cost
- Author origin story: $1.00
- Chapter 1 rewrite: $1.50
- Example replacement (10 chapters): $4.00
- Mechanism deepening (10 chapters): $15.00
- AI marker removal (10 chapters): $3.00
- Engagement elements (10 chapters): $3.50
- **Total per book: ~$28**

### Timeline for Books/Book Rescues
- **Book 1 (Smart Money Finance)**: 1 day ($28)
  - Focus on quality validation
  - Document exactly what changed
- **Book 2 (Digital Marketing Strategy)**: 0.5 day ($28)
  - Reuse templates from Book 1
- **Books 3-10**: 4 days ($224)
  - 2 per day in parallel
  - Use proven templates

### Cost
- Total for 10 Books/Book rescues: ~$280
- (Uses Opus heavily, more complex work)

---

## TOTAL PORTFOLIO EXECUTION

### Timeline
- **Phase 1 (Pilot)**: 1 day, $13
- **Phase 2 (Elliott completion)**: 1 day, $32
- **Phase 3 (BookCLI workbooks)**: 2 days, $59
- **Phase 4 (Books/Book rescues)**: 5 days, $280
- **TOTAL**: 9 days, ~$384 API cost

### Success Metrics (How to Know It Worked)
- ✓ Elliott books: 8.5 → 9.2/10 (+0.7 points)
- ✓ BookCLI workbooks: 7.5 → 8.3/10 (+0.8 points)
- ✓ Books/Book rescues: 5.5 → 6.5/10 (+1.0 points)
- ✓ Portfolio average: 7.3 → 8.0/10

### Validation Method
For each phase:
1. Read 1-2 full books word-for-word
2. Measure on these dimensions:
   - **Specificity**: Generic → Named/quantified? (scale 1-5)
   - **Authenticity**: Template-y → Human voice? (scale 1-5)
   - **Engagement**: Instructional → Interactive? (scale 1-5)
   - **Depth**: Surface → Mechanism explained? (scale 1-5)
   - **Completeness**: Missing elements added? (scale 1-5)
3. Average score should improve by 1-2 points
4. Only proceed to next phase if validated

---

## IMMEDIATE ACTIONS (First 30 Minutes)

1. **Verify API Access**
   ```bash
   python3 -c "import anthropic; print('API working')" 2>&1
   ```

2. **Create Working Directory**
   ```bash
   mkdir -p /mnt/e/projects/content-expansion-work
   cd /mnt/e/projects/content-expansion-work
   ```

3. **Backup Source Files**
   ```bash
   cp -r /home/elliott/output/books /home/elliott/output/books.backup.$(date +%Y%m%d)
   cp -r /mnt/e/projects/bookcli/output/books /mnt/e/projects/bookcli/output/books.backup.$(date +%Y%m%d)
   ```

4. **Choose Start Book**
   - Recommended: The Habit Blueprint (most complete, easiest to validate)
   - Extract first 3 chapters to process in parallel

5. **Create Test Prompt**
   - Use prompt template from Phase 1 above
   - Test with 1 chapter first
   - Validate output quality before processing all

---

## RISK MITIGATION CHECKLIST

- [ ] All source files backed up
- [ ] API key confirmed working
- [ ] Understand rate limits before starting
- [ ] Plan for API failures (have retry strategy)
- [ ] Document every API call (cost + tokens)
- [ ] Save all intermediate results
- [ ] Validate quality before next phase
- [ ] Keep original files untouched until validation
- [ ] Track total cost against $384 budget
- [ ] Have plan for if results don't meet goals

---

**Status**: READY FOR EXECUTION
**Next Step**: Confirm API access and select starting book
