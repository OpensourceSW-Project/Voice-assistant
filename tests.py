import pandas as pd
import chardet

def detect_encoding(file_path):
    with open(file_path, 'rb') as f:
        result = chardet.detect(f.read())
        print(1)
    return result['encoding']

def preview_csv(csv_file_path):
    try:
        # Detect encoding of the CSV file
        encoding = detect_encoding(csv_file_path)

        # Read CSV file with the detected encoding
        df = pd.read_csv(csv_file_path, encoding=encoding)

        # Show the first 5 rows
        print("파일 인코딩:", encoding)
        print("CSV 데이터 미리보기:")
        print(df.head())

    except Exception as e:
        print(f"오류 발생: {e}")


if __name__ == "__main__":
    # CSV 파일 경로
    csv_file = 'combined_yeogi_data.csv'

    preview_csv(csv_file)