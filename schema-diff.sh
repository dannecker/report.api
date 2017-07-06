#!/bin/bash
# This is schema-diff.sh
# It helps keep diffis of schemas under control
# Example
# ./schema-diff.sh capitation_contract

whotest[0]='test' || (echo 'Failure: arrays not supported in this version of
bash.' && exit 2)

# Let's define a list of schemas in format
# schema_name github_url local_path
schemalist=(
        "capitation_contract
        https://raw.githubusercontent.com/Nebo15/prm.api/master/lib/prm/capitation_contract.ex
        lib/report/replica/schemas/capitation_contract.ex"
        "declaration
        https://raw.githubusercontent.com/Nebo15/ops.api/master/lib/ops/declaration.ex
        lib/report/replica/schemas/declaration.ex"
        "devision
        https://raw.githubusercontent.com/Nebo15/prm.api/master/lib/prm/entities/division.ex
        lib/report/replica/schemas/division.ex"
        "employee_doctor
        https://raw.githubusercontent.com/Nebo15/prm.api/master/lib/prm/employees/employee_doctor.ex
        lib/report/replica/schemas/employee_doctor.ex"
        "employee
        https://raw.githubusercontent.com/Nebo15/prm.api/master/lib/prm/employees/employee.ex
        lib/report/replica/schemas/employee.ex"
        "settelment
        https://raw.githubusercontent.com/Nebo15/uaddresses.api/dcfb3de085878362aeda0e5fe9bb7443b6c6bf0c/lib/uaddresses_api/settlements/settlement.ex
        lib/report/replica/schemas/settelment.ex"
)

for list in "${schemalist[@]}"
do
    item=$(echo $list | head -n1 | awk '{print $1;}')
    input=$1
    if [ "$1" == "$item" ]; then
        github_url=$(echo $list | head -n1 | awk '{print $2;}')
        local_path=$(echo $list | head -n1 | awk '{print $3;}')
        curl -s $github_url | diff  --suppress-common-lines -y $local_path -
    fi
done
