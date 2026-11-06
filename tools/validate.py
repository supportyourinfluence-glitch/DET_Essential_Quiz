"""game/data.js 단어 데이터를 검사한다. 사용법: python tools/validate.py"""
import json
import re
import sys
from pathlib import Path

DATA = Path(__file__).resolve().parent.parent / "game" / "data.js"

# 문장 속 형태가 표제어와 다를 수밖에 없는 항목 (표제어: 문장 속 빈칸 정답)
VARIABLE = {
    "allow A to B": "allow",
    "provide A for B": "provide",
    "keep -ing": "keep",
    "care about[for]": "care about",
    "blonde(=blond)": "blonde",
    "broaden one's horizons": "broaden your horizons",
}


def load():
    days, day = {}, None
    for line in DATA.read_text(encoding="utf-8").splitlines():
        m = re.match(r"D\((\d+),\[", line)
        if m:
            day = int(m.group(1))
            days[day] = []
        elif line.startswith('["'):
            days[day].append(json.loads(line.rstrip(",")))
    return days


def check(days):
    errors = []
    if sorted(days) != list(range(1, 11)):
        errors.append(f"DAY 구성이 다름: {sorted(days)}")
    seen_real = {}
    for day, rows in days.items():
        if len(rows) != 50:
            errors.append(f"DAY {day}: {len(rows)}개")
        for no, row in enumerate(rows, 1):
            tag = f"DAY {day} #{no:03d}"
            if len(row) != 5 or not all(row[:4]):
                errors.append(f"{tag}: 빈 칸 또는 열 개수 오류 {row}")
                continue
            word, _, sentence, _, fake = row
            spans = re.findall(r"\{(.+?)\}", sentence)
            if len(spans) != 1:
                errors.append(f"{tag} {word}: 표시된 빈칸 {len(spans)}개")
            elif spans[0].lower() != VARIABLE.get(word, word).lower():
                errors.append(f"{tag} {word}: 빈칸 '{spans[0]}' 불일치")
            is_single = re.fullmatch(r"[A-Za-z]+(\(=[a-z]+\))?", word)
            if is_single and not fake:
                errors.append(f"{tag} {word}: 가짜 단어 없음")
            if not is_single and fake:
                errors.append(f"{tag} {word}: 표현 항목에 가짜 단어 있음")
            if word.lower() in seen_real:
                errors.append(f"{tag} {word}: {seen_real[word.lower()]}와 중복")
            seen_real[word.lower()] = tag
    for day, rows in days.items():
        for no in range(1, len(rows) + 1):
            for kind in ("w", "s"):
                if not (DATA.parent / "audio" / kind / f"{day}-{no}.mp3").is_file():
                    errors.append(f"음성 파일 없음: {kind}/{day}-{no}.mp3")
    fakes = {}
    for day, rows in days.items():
        for row in rows:
            fake = row[4].lower()
            if not fake:
                continue
            if fake in seen_real:
                errors.append(f"가짜 단어 '{fake}'가 단어 목록과 겹침")
            if fake in fakes:
                errors.append(f"가짜 단어 '{fake}' 중복")
            if fake == re.sub(r"\(.*", "", row[0]).lower():
                errors.append(f"가짜 단어 '{fake}'가 원래 단어와 같음")
            fakes[fake] = row[0]
    return errors


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    days = load()
    errors = check(days)
    total = sum(len(r) for r in days.values())
    fakes = sum(1 for r in days.values() for row in r if row[4])
    print(f"단어 {total}개, 가짜 단어 {fakes}개, 표현 {total - fakes}개")
    for e in errors:
        print("오류:", e)
    print("통과" if not errors else f"오류 {len(errors)}건")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
