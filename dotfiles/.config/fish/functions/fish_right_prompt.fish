function fish_right_prompt
    set -l cmd_status $status
    if test $cmd_status -ne 0
        echo -n (set_color red)"[$cmd_status] "
    end

    set -l duration "$CMD_DURATION"
    if test $duration -gt 1000
        set -l duration (math $duration / 1000)
        set -l text (math --scale=0 $duration % 60)s
        if test $duration -gt 60
            set text (math --scale=0 $duration / 60 % 60)m $text
            if test $duration -gt 3600
                set text (math --scale=0 $duration / 3600 % 24)h $text
                if test $duration -gt 86400
                    set text (math --scale=0 $duration / 86400)d $text
                end
            end
        end
        echo -n (set_color brgrey)"$text"
    end

    set_color normal
end
