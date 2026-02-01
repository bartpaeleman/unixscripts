import sys
import collections
import re

def analyze_text(filepath):
    try:
        lines_count = 0
        word_counts = collections.Counter()
        chars_count = 0
        non_space_chars_count = 0
        total_words_count = 0

        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                lines_count += 1
                chars_count += len(line)
                non_space_chars_count += len(line.replace(" ", "").replace("\n", ""))

                words = re.findall(r'\b\w+\b', line.lower())
                word_counts.update(words)
                total_words_count += len(words)

        top_10 = word_counts.most_common(10)

        print(f"--- Statistics for {filepath} ---")
        print(f"Lines:            {lines_count}")
        print(f"Words:            {total_words_count}")
        print(f"Characters:       {chars_count}")
        print(f"Chars (no space): {non_space_chars_count}")
        print("-" * 30)
        print("Top 10 Words:")
        for word, count in top_10:
            print(f"  {word}: {count}")

    except Exception as e:
        print(f"Error analyzing text: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 text_stats.py <file>")
        sys.exit(1)

    analyze_text(sys.argv[1])
