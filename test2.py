from datetime import datetime
from intelmaster.src.analyzer import IntelAnalyzer

analyzer = IntelAnalyzer('/tmp/dummy_config2.json', '/tmp/dummy2', '/tmp/dummy2', 'intelmaster/assets/style.css')
analyzer.process_all()
analyzer.generate_report()
