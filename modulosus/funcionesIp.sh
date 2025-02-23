#!/bin/bash
function esIpValida(){
	local regex="^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    if [[ $1 =~ $regex ]]; then
        return 0
    else
        return 1
    fi
}