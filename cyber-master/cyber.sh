#!/bin/bash
# Master Wrapper Script for cyber-master toolset

CYBER_MASTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_WRAPPER="$CYBER_MASTER_DIR/common/run_python.sh"
ALIASES="$CYBER_MASTER_DIR/common/aliases.sh"

source "$ALIASES"

show_help() {
    echo "Cyber-Master: Modular Cybersecurity Toolset"
    echo "=========================================="
    echo "Usage: ./cyber.sh <command> [arguments]"
    echo ""
    echo "Commands:"
    echo "  mail <file>       Run the Phishing Email Analyzer on an .eml file."
    echo "  enrich <target>   Run the Passive DNS & URL Enricher."
    echo "  score             Run the Risk Scorer (requires JSON via stdin)."
    echo "  report [format]   Generate a Markdown or HTML report (requires JSON via stdin)."
    echo ""
    echo "Pipeline Wrappers:"
    echo "  threatctx <target> Run the full enrichment, scoring, and reporting pipeline."
    echo "  mhdr <file>        Extract key findings (IP, SPF, DKIM) from an email."
    echo "  mailtrace <file>   Analyze an email and display the Terminal UI."
    echo ""
}

if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

COMMAND=$1
shift

case "$COMMAND" in
    mail)
        "$PYTHON_WRAPPER" "$CYBER_MASTER_DIR/mail/mail_analyzer.py" "$@"
        ;;
    enrich)
        "$PYTHON_WRAPPER" "$CYBER_MASTER_DIR/enrich/enricher.py" "$@"
        ;;
    score)
        "$PYTHON_WRAPPER" "$CYBER_MASTER_DIR/scoring/risk_scorer.py" "$@"
        ;;
    report)
        "$PYTHON_WRAPPER" "$CYBER_MASTER_DIR/reporting/reporter.py" "$@"
        ;;
    threatctx)
        threatctx "$@"
        ;;
    mhdr)
        if [ -n "$1" ] && [ -f "$1" ]; then
            cat "$1" | mhdr
        else
            mhdr
        fi
        ;;
    mailtrace)
        mailtrace "$@"
        ;;
    --help|-h|help)
        show_help
        ;;
    *)
        echo "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac
