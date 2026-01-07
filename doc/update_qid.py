import csv

def update_csv(file_path, is_truth=False):
    rows = []
    with open(file_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        for row in reader:
            # Update q_id to match Order
            row['q_id'] = row['Order']
            rows.append(row)

    with open(file_path, 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    print(f"Updated {file_path}")

update_csv('/Users/anmijung/Desktop/TalkBingo/doc/TruthQuizData.csv', is_truth=True)
update_csv('/Users/anmijung/Desktop/TalkBingo/doc/BalanceQuizData.csv', is_truth=False)
