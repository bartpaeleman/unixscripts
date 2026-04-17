from datetime import datetime, timedelta

cutoff = datetime.now() - timedelta(days=7)
print("Cutoff date:", cutoff)

# The item's date is "Wed, 17 Apr 2024 10:00:00 GMT" (It's currently 2026 as per sandbox clock)
from intelmaster.src.analyzer import IntelAnalyzer
analyzer = IntelAnalyzer('/tmp/dummy_config.json', '/tmp/dummy', '/tmp/dummy', 'intelmaster/assets/style.css')
analyzer.process_all()
print("Findings count:", len(analyzer.findings))

analyzer.cutoff_date = datetime(2000, 1, 1) # Set old cutoff
analyzer.findings = []
analyzer.process_all()
print("Findings count with old cutoff:", len(analyzer.findings))
analyzer.generate_report()
