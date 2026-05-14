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
    echo "  report [format]   Generate a Markdown, HTML, or PDF report (requires JSON via stdin)."
    echo ""
    echo "Pipeline Wrappers:"
    echo "  threatctx <target> Run the full enrichment, scoring, and reporting pipeline."
    echo "  mhdr <file>        Extract key findings (IP, SPF, DKIM) from an email."
    echo "  mailtrace <file>   Analyze an email and display the Terminal UI."
    echo ""
    echo "Interactive:"
    echo "  interactive        Start the interactive wizard to guide you through tools."
    echo ""
}

run_interactive() {
    echo -e "\033[1;36mCyber-Master Interactive Mode\033[0m"
    echo "1) Email/Phishing Analysis"
    echo "2) Domain/IP Recon & Full Threat Context"
    read -p "Select module (1/2): " module_choice

    if [ "$module_choice" == "1" ]; then
        read -p "Enter path to .eml file or raw headers: " eml_file
        if [ ! -f "$eml_file" ]; then
            echo "File not found: $eml_file"
            exit 1
        fi
        echo "1) Show Terminal UI (mailtrace)"
        echo "2) Extract key findings (mhdr)"
        echo "3) Output raw JSON"
        read -p "Select action (1/2/3): " email_action
        case "$email_action" in
            1) mailtrace "$eml_file" ;;
            2) cat "$eml_file" | mhdr ;;
            3) "$PYTHON_WRAPPER" "$CYBER_MASTER_DIR/mail/mail_analyzer.py" "$eml_file" --json ;;
            *) echo "Invalid choice." ;;
        esac

    elif [ "$module_choice" == "2" ]; then
        read -p "Enter target IP or Domain: " target
        if [ -z "$target" ]; then
            echo "Target cannot be empty."
            exit 1
        fi
        echo "1) Run Full Threat Context and generate Markdown Report (threatctx)"
        echo "2) Output raw JSON (Enrich + Score)"
        echo "3) Generate HTML Report"
        echo "4) Generate PDF Report"
        read -p "Select action (1/2/3/4): " recon_action
        case "$recon_action" in
            1) threatctx "$target" ;;
            2) echo "{\"target\": \"$target\"}" | "$PYTHON_WRAPPER" "$CYBER_MASTER_DIR/enrich/enricher.py" | "$PYTHON_WRAPPER" "$CYBER_MASTER_DIR/scoring/risk_scorer.py" ;;
            3) echo "{\"target\": \"$target\"}" | "$PYTHON_WRAPPER" "$CYBER_MASTER_DIR/enrich/enricher.py" | "$PYTHON_WRAPPER" "$CYBER_MASTER_DIR/scoring/risk_scorer.py" | "$PYTHON_WRAPPER" "$CYBER_MASTER_DIR/reporting/reporter.py" --format html ;;
            4) echo "{\"target\": \"$target\"}" | "$PYTHON_WRAPPER" "$CYBER_MASTER_DIR/enrich/enricher.py" | "$PYTHON_WRAPPER" "$CYBER_MASTER_DIR/scoring/risk_scorer.py" | "$PYTHON_WRAPPER" "$CYBER_MASTER_DIR/reporting/reporter.py" --format pdf ;;
            *) echo "Invalid choice." ;;
        esac
    else
        echo "Invalid choice."
    fi
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
    interactive)
        run_interactive
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
