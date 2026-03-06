#!/bin/bash
# KDP Upload Verification Script
# Verifies all books are ready for KDP upload

echo "=========================================="
echo "KDP UPLOAD READINESS VERIFICATION"
echo "=========================================="
echo ""

BOOKS_DIR="/mnt/e/projects/books/book"
READY_COUNT=0
ISSUES=0

TIER1_BOOKS=(
  "Digital_Marketing_Strategy"
  "Launch_Scale_Entrepreneur"
  "Mastering_Leadership"
  "Smart_Money_Finance"
  "Remote_First"
  "The_Habit_Blueprint"
  "The_Decision_Architect"
  "Time_Mastery_Productivity"
)

for book in "${TIER1_BOOKS[@]}"; do
  echo "Checking: $book"
  BOOK_PATH="$BOOKS_DIR/$book"

  if [ ! -d "$BOOK_PATH" ]; then
    echo "  ❌ Directory not found"
    ((ISSUES++))
    echo ""
    continue
  fi

  # Check for chapter files
  CHAPTER_FILES=$(find "$BOOK_PATH" -name "*.md" -not -name "*SUMMARY*" -not -name "*REPORT*" | wc -l)
  if [ "$CHAPTER_FILES" -gt 0 ]; then
    echo "  ✅ Chapters: $CHAPTER_FILES files"
  else
    echo "  ❌ No chapter files found"
    ((ISSUES++))
  fi

  # Check for EPUB
  EPUB_FILE=$(find "$BOOK_PATH" -name "*.epub" | head -1)
  if [ -f "$EPUB_FILE" ]; then
    EPUB_SIZE=$(du -h "$EPUB_FILE" | cut -f1)
    echo "  ✅ EPUB: $EPUB_SIZE"
  else
    echo "  ❌ EPUB file missing"
    ((ISSUES++))
  fi

  # Check for PDF
  PDF_FILE=$(find "$BOOK_PATH" -name "*.pdf" -not -name "*.backup" | head -1)
  if [ -f "$PDF_FILE" ]; then
    PDF_SIZE=$(du -h "$PDF_FILE" | cut -f1)
    echo "  ✅ PDF: $PDF_SIZE"
  else
    echo "  ❌ PDF file missing"
    ((ISSUES++))
  fi

  # Check word count
  WORD_COUNT=$(wc -w "$BOOK_PATH"/*.md 2>/dev/null | tail -1 | awk '{print $1}')
  if [ "$WORD_COUNT" -gt 2500 ]; then
    echo "  ✅ Word Count: $WORD_COUNT"
  else
    echo "  ❌ Word Count Too Low: $WORD_COUNT (min: 2,500)"
    ((ISSUES++))
  fi

  # Check metadata documentation
  if [ -f "$BOOK_PATH"/*SUMMARY*.md ]; then
    echo "  ✅ Metadata: Summary found"
  else
    echo "  ⚠️  Metadata: No summary found"
  fi

  ((READY_COUNT++))
  echo ""
done

echo "=========================================="
echo "SUMMARY"
echo "=========================================="
echo "Books Checked: $READY_COUNT"
echo "Critical Issues: $ISSUES"

if [ "$ISSUES" -eq 0 ]; then
  echo ""
  echo "✅ ALL BOOKS READY FOR KDP UPLOAD"
  echo ""
  echo "Next Steps:"
  echo "1. Create cover images for each book"
  echo "2. Go to https://kdp.amazon.com"
  echo "3. Upload first ebook (EPUB file)"
  echo "4. Add cover image and metadata"
  echo "5. Set price to \$9.99"
  echo "6. Publish ebook"
  echo "7. Upload paperback (PDF file) using same metadata"
  echo ""
else
  echo ""
  echo "⚠️  ISSUES FOUND - FIX BEFORE UPLOADING"
  echo ""
fi
