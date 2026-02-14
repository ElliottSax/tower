/**
 * AWS Lambda: Text Analysis
 *
 * Analyzes text and returns comprehensive statistics
 */

exports.handler = async (event) => {
  const startTime = Date.now();

  try {
    const body = JSON.parse(event.body || '{}');
    const text = body.text || '';

    // Perform analysis
    const words = text.split(/\s+/).filter(w => w.length > 0);
    const sentences = text.split(/[.!?]+/).filter(s => s.trim().length > 0);
    const paragraphs = text.split(/\n\n+/).filter(p => p.trim().length > 0);
    const lines = text.split(/\n/).filter(l => l.trim().length > 0);

    const wordLengths = words.map(w => w.length);
    const avgWordLength = wordLengths.reduce((a, b) => a + b, 0) / (words.length || 1);
    const maxWordLength = Math.max(...wordLengths, 0);
    const minWordLength = Math.min(...wordLengths, Infinity);

    // Character analysis
    const letters = text.match(/[a-zA-Z]/g) || [];
    const digits = text.match(/\d/g) || [];
    const uppercase = text.match(/[A-Z]/g) || [];
    const lowercase = text.match(/[a-z]/g) || [];
    const spaces = text.match(/\s/g) || [];
    const punctuation = text.match(/[.,!?;:]/g) || [];

    // Unique words
    const uniqueWords = new Set(words.map(w => w.toLowerCase()));

    const duration = Date.now() - startTime;

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Credentials': true,
      },
      body: JSON.stringify({
        text: {
          length: text.length,
          words: words.length,
          sentences: sentences.length,
          paragraphs: paragraphs.length,
          lines: lines.length,
          uniqueWords: uniqueWords.size
        },
        words: {
          count: words.length,
          avgLength: parseFloat(avgWordLength.toFixed(2)),
          maxLength: maxWordLength,
          minLength: minWordLength === Infinity ? 0 : minWordLength,
          unique: uniqueWords.size,
          uniqueRatio: parseFloat((uniqueWords.size / (words.length || 1)).toFixed(3))
        },
        characters: {
          total: text.length,
          letters: letters.length,
          digits: digits.length,
          uppercase: uppercase.length,
          lowercase: lowercase.length,
          spaces: spaces.length,
          punctuation: punctuation.length,
          uppercaseRatio: parseFloat((uppercase.length / (letters.length || 1)).toFixed(3))
        },
        readability: {
          avgWordsPerSentence: parseFloat(((words.length || 0) / (sentences.length || 1)).toFixed(2)),
          avgSentencesPerParagraph: parseFloat(((sentences.length || 0) / (paragraphs.length || 1)).toFixed(2))
        },
        meta: {
          duration,
          provider: 'aws-lambda',
          region: process.env.AWS_REGION,
          memoryUsed: process.memoryUsage().heapUsed,
          timestamp: new Date().toISOString()
        }
      })
    };
  } catch (error) {
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        error: 'Internal Server Error',
        message: error.message
      })
    };
  }
};
