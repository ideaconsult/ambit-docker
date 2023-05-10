#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

#    Name     :: Target URL           Params :: 0     :: 1  :: 2 :: 3     :: 4   :: 5                                         :: 6  :: 7 :: 8  :: 9
targets=(
    'NANoREG  :: http://127.0.0.1:8080/ambit :: Fe2O3 :: 32 :: 5 :: CAS   :: 156 :: NNRG-2cb3446e-c9c4-24f2-4519-e06fa3aacb50 :: 6  :: 2 :: 5  :: NNRG-2cb3446e-c9c4-24f2-4519-e06fa3aacb50'
    'NanoReg2 :: http://127.0.0.1:8081/ambit :: O2Si  :: 1  :: 3 :: CasRN :: 38  :: NRG2-902e5aee-05e3-3ca9-8ded-9d57092c2131 :: 34 :: 1 :: 12 :: NRG2-b3f90c4c-c132-36b3-a693-ba089f261705'
)

#    Test name                    :: Test endpoint                   :: Result parser                         :: Result validation
# shellcheck disable=SC2016
tests=(
    'Algorithms: [List]           :: /algorithm                      :: jq -r ".algorithm|length"             :: -eq 141'
    'Algorithms: Benigni/Bossa    :: /algorithm/toxtreecarc          :: jq -r .algorithm[].content            :: == mutant.BB_CarcMutRules'
    'Algorithms: Cramer           :: /algorithm/toxtreecramer        :: jq -r .algorithm[].content            :: == toxTree.tree.cramer.CramerRules'
    'Algorithms: ILSI/Kroes       :: /algorithm/toxtreekroes         :: jq -r .algorithm[].content            :: == toxtree.plugins.kroes.Kroes1Tree'
    'Algorithms: J48              :: /algorithm/J48                  :: jq -r .algorithm[].content            :: == weka.classifiers.trees.J48'
    'Algorithms: LRR              :: /algorithm/LR                   :: jq -r .algorithm[].content            :: == weka.classifiers.functions.LinearRegression'
    'Algorithms: pKa              :: /algorithm/pka                  :: jq -r .algorithm[].content            :: == ambit2.descriptors.PKASmartsDescriptor'
    'Algorithms: Simple K-means   :: /algorithm/SimpleKMeans         :: jq -r .algorithm[].content            :: == weka.clusterers.SimpleKMeans'
    'Compounds:  Compound Repr.   :: /compound/1                     :: jq -r .dataEntry[].compound.formula   :: == ___0___'
    'Compounds:  Feature Values   :: /compound/___1___/feature       :: jq -r [.feature[]][0].title           :: == CasRN'
    'Compounds:  Conformers       :: /compound/1/conformer           :: jq -r ".dataEntry|length"             :: -eq 1'
    'Compounds:  Conformer Repr.  :: /compound/1/conformer/1         :: jq -r .dataEntry[].compound.formula   :: == ___0___'
    'Compounds:  Search by PV     :: /compound?search=7631-86-9      :: jq -r .dataEntry[].compound.formula   :: == O2Si'
    'Feature:    All Features     :: /feature                        :: jq -r ".feature|length"               :: -eq ___2___'
    'Feature:    All Per Compound :: /compound/___1___/feature       :: jq -r ".feature|length"               :: -eq 2'
    'Feature:    Description      :: /feature/1                      :: jq -r [.feature[]][0].title           :: == ___3___'
    'Feature:    Search           :: /feature?search=___3___         :: jq -r [.feature[]][0].title           :: == ___3___'
    'Tasks:      [List]           :: /task                           :: jq -r ".task|length"                  :: -eq 0'
    'Substances: [List]           :: /substance                      :: jq -r ".substance|length"             :: -eq ___4___'
    'Substances: Studies          :: /substance/___5___/study        :: jq -r ".study|length"                 :: -eq ___6___'
    'Substances: Owners           :: /substanceowners                :: jq -r ".facet|length"                 :: -eq ___7___'
    'Substances: Study Summary    :: /substance/___5___/studysummary :: jq -r ".facet|length"                 :: -eq ___8___'
    'Substances: Composition      :: /substance/___5___/composition  :: jq -r .composition[0].compositionUUID :: == ___9___'
)
# TODO:
# Compounds: CmpdFValues
# Models: all
# Search: all
# Structures: all
# Substances: SubstanceStuct [sic]
# Substances: StructPerOwner

curl_cmd='curl --silent --header "Accept: application/json"'

result_FAIL='\033[1;31mFAIL\033[0m'
result_OK='\033[1;32mOK\033[0m'

fail_count=0


trim() {
    if [[ $1 -eq 1 ]]; then
        sed -e 's|^[[:space:]]\+||' -e 's|[[:space:]]\+$||'
    else
        cat
    fi
}


target_get() {
    local i
    case $1 in
        name)      i=1; do_trim=0 ;;
        url)       i=2; do_trim=1 ;;
        param)     i=$(( $3 + 3 )); do_trim=1 ;;
    esac
    printf '%s' "$2" | awk -F ' :: ' "{ print \$$i }" | trim "${do_trim}"
}


test_get() {
    local i
    case $1 in
        name)      i=1; do_trim=0 ;;
        endpoint)  i=2; do_trim=1 ;;
        parser)    i=3; do_trim=1 ;;
        check)     i=4; do_trim=1 ;;
    esac
    printf '%s' "$2" | awk -F ' :: ' "{ print \$$i }" | trim "${do_trim}"
}


for spec in "${tests[@]}"; do
    for target in "${targets[@]}"; do

        if [[ ${spec} == *___* ]]; then
            param_count="$(printf '%s' "${spec}" | awk -F '___' '{ print NF }')"
            parsed_spec="${spec}"
            for (( p = 2; p < param_count; p = p + 2 )); do
                param_number="$(printf '%s' "${spec}" | awk -F '___' "{ print \$${p} }")"
                param_value="$(target_get param "${target}" "${param_number}")"
                parsed_spec="${parsed_spec/___${param_number}___/${param_value}}"
            done
        else
            parsed_spec="${spec}"
        fi

        targetname="$(target_get name "${target}")"
        testurl="$(target_get url "${target}")"
        testname="$(test_get name "${parsed_spec}")"
        endpoint="$(test_get endpoint "${parsed_spec}")"
        parser="$(test_get parser "${parsed_spec}")"
        check="$(test_get check "${parsed_spec}")"

        echo -n "${testname} on ${targetname} ... "

        query="$( eval "${curl_cmd} \"${testurl}${endpoint}\" | ${parser}" )"
        [[ ${1:-} == debug ]] && echo -n "${query} "
        if eval "[[ ${query} ${check} ]]"; then
            echo -e "${result_OK}"
        else
            echo -en "${result_FAIL}"
            printf ' Check: "%s" Value: "%s"\n' "${check}" "${query}"
            (( fail_count++ )) || true
        fi

    done
done

[[ ${fail_count} -eq 0 ]] || false
