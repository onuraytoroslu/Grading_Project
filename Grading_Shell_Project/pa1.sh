#!/bin/bash

# Define paths and filenames
max_grade="$1"
correct_output_file="$2"
submissions_dir="$3"
grading_dir="grading"

# Create grading directory
mkdir -p "$grading_dir"
log_file="$grading_dir/log.txt"
result_file="$grading_dir/result.txt"
touch "$log_file" "$result_file"

echo "Checking the arguments.."

# Argument validations
if ! [[ "$max_grade" =~ ^[0-9]+$ ]] || [ "$max_grade" -le 0 ]; then
    echo "Max grade should be a positive integer"
    exit 1
fi

if [ ! -f "$correct_output_file" ]; then
    echo "Correct output file does not exist!"
    exit 1
fi

if [ ! -d "$submissions_dir" ] || [ ! "$(ls -A $submissions_dir)" ]; then
    echo "Submissions folder does not exist or is empty!"
    exit 1
fi

num_students=$(find "$submissions_dir" -type f -name '*.sh' | wc -l)
echo "$num_students number of students submitted homework."

# Grade each submission
find "$submissions_dir" -type f -name '*.sh' | while read submission; do
    filename=$(basename "$submission")
    if ! [[ "$filename" =~ ^322_h1_[0-9]{9}\.sh$ ]]; then
        echo "Incorrect file name format: $filename" >> "$log_file"
        continue
    fi

    student_id=$(echo "$filename" | cut -d'_' -f3 | cut -d'.' -f1)
    echo "Grading process for $filename is started.. checking the file permission..."
    chmod +x "$submission"
    echo "Changed permission of $filename to executable id is $student_id"

    output_file="$grading_dir/${filename%.sh}_out.txt"
    if ! timeout 60 bash "$submission" > "$output_file" 2>&1; then
        echo "Student $student_id: too long execution" >> "$log_file"
        echo "Student ID: $student_id Grade: 0" >> "$result_file"
        continue
    fi

    diff_count=$(diff -y --suppress-common-lines "$output_file" "$correct_output_file" | wc -l)
    grade=$(($max_grade - diff_count))
    echo "Student ID: $student_id Grade: $grade" >> "$result_file"
done

echo "*** Grading completed ***"

