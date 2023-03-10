#! /bin/bash

for arg in $@;do
    case $arg in
        -c|--config)
            config_file="$2"
            config=true
            shift 2
            ;;
        -f|--file)
            dump_file="$2"
            shift 2
            ;;
        -h|--help)
            exit
            ;;
        -o|--output)
            output_file="$2"
            shift 2
            ;;
        -v|--verbose)
            log=true
            shift
            ;;
        -g|--game)
            game_number="$2"
            shift 2
            ;;
        -k|--key)
            code="$2"
            shift 2
            ;;
    esac
done
unit=100 # > 80
r_star=$(bc <<< "sqrt($unit)-6")
r_main=$(( $r_star*2 ))

source "$config_file" && echo "Sourced config"

if [ -e "$dump_file" ]; then
    echo "Working with dump $dump_file";
else
    if [ $dump_file ]; then
        read answer -p "Dump file could not be read. Download new one? (y/N) "
        case $answer in
            y|Y|yes) ;;
            *) exit 1 ;;
        esac
    fi
    dump_file="dump-$(date +%d.%m.%y-%h).json"

    [ -z "$game_number" ] && \
        { echo "Game number is not set"; exit 1; }
    [ -z "$code" ] && \
        { echo "API key is not set"    ; exit 1; }

curl https://np.ironhelmet.com/api  \
    -X POST                         \
    -d game_number=$game_number     \
    -d code=$code                   \
    -d api_version=0.1              \
     > $dump_file || exit 1
fi

if [ -z "$(cat "$config_file")" ]; then
    echo "game_number=$game_number" >> "$config_file"
    echo "code=$code"  >> "$config_file"
fi

if [ -z $teams ]; then
    echo  "What teams there are?"
    read -a teams

    echo  "What colors they use?"
    read -a teams_colors

    if [ $config ]; then
        echo "teams=(${teams[@]})" >> "$config_file"
        echo "teams_colors=(${teams_colors[@]})" >> "$config_file"
        echo "players=(" >> "$config_file"
    fi
    for team in ${teams[@]}; do
        echo  "Who belongs to team $team?"
        read -a players_entered
        for player in ${players_entered[@]}; do
            players["$player"]="$team"
            [ $config ] && echo "[$player]=\"$team\" " >> "$config_file"
        done
    done
    [ $config ] && echo ")" >> "$config_file"

fi

cords=$(jq -r '.scanning_data.stars|.[]|.x' $dump_file | sort -h)
stars_total=$( wc -l <<< $cords)
min_cord=$(head -n 1 <<< $cords)
max_cord=$(tail -n 1 <<< $cords)
units_x=$( bc <<< "($min_cord*-1+$max_cord+2.5)/1" )
home_x=$(  bc <<< "$units_x - $max_cord -2" )

cords=$(jq -r '.scanning_data.stars|.[]|.y' $dump_file | sort -h)
min_cord=$(head -n 1 <<< $cords)
max_cord=$(tail -n 1 <<< $cords)
units_y=$( bc <<< "($min_cord*-1+$max_cord+2.5)/1" )
home_y=$(  bc <<< "$units_y - $max_cord -2" )
echo "Grid:${units_x}x${units_y}"
echo "Estimated home: ${home_x}x${home_y}"

while read x y player; do
    echo -en "\rSorting stars:$stars_done/$stars_total"
    source <(
        bc <<< "
        x=(( $x + $home_x ) * $unit + $unit.5)/1
        y=(( $y + $home_y ) * $unit + $unit.5)/1
        s=$player/8
        print \"x=\",x,\"\n\"
        print \"y=\",y,\"\n\"
        print \"shape=\",s,\"\n\"
        ")
    r=$r_star
    render_white="${render_white} circle $x,$y $(($x+$r)),$y"
    if [ ! $player = -1 ]; then
        r=$r_main
        case $shape in
            #Circle
            0) geometry="circle $x,$y %[fx:$x+$r],$y"
                ;;
            #Square
            1) geometry="rectangle %[fx:$x-$r],%[fx:$y-$r] %[fx:$x+$r],%[fx:$y+$r]"
                ;;
            #Hexagon
            2) geometry="polygon $x,%[fx:$y+$r] %[fx:$x+$r*sin(1)],%[fx:$y+$r*cos(1)] %[fx:$x+$r*sin(1)],%[fx:$y-$r*cos(1)] $x,%[fx:$y-$r] %[fx:$x-$r*sin(1)],%[fx:$y-$r*cos(1)] %[fx:$x-$r*sin(1)],%[fx:$y+$r*cos(1)]"
                ;;
            #Triangle
            3) geometry="polygon $x,%[fx:$y-$r*1.3] %[fx:$x+$r*cos(0.5)*1.3],%[fx:$y+$r*sin(0.5)*1.3] %[fx:$x-$r*cos(0.5)*1.3],%[fx:$y+$r*sin(0.5)*1.3]"
                ;;
            #Cross
            4) geometry="polygon %[fx:$x-$r*sin(0.45)*1.15],%[fx:$y-$r*cos(0.45)*1.15] %[fx:$x+$r*sin(0.45)*1.15],%[fx:$y-$r*cos(0.45)*1.15] %[fx:$x+$r*sin(0.45)*1.15],%[fx:$y-$r*cos(1.05)*1.15] %[fx:$x+$r*sin(1.05)*1.15],%[fx:$y-$r*cos(1.05)*1.15] %[fx:$x+$r*sin(1.05)*1.15],%[fx:$y+$r*cos(1.05)*1.15] %[fx:$x+$r*sin(0.45)*1.15],%[fx:$y+$r*cos(1.05)*1.15] %[fx:$x+$r*sin(0.45)*1.15],%[fx:$y+$r*cos(0.45)*1.15] %[fx:$x-$r*sin(0.45)*1.15],%[fx:$y+$r*cos(0.45)*1.15] %[fx:$x-$r*sin(0.45)*1.15],%[fx:$y+$r*cos(1.05)*1.15] %[fx:$x-$r*sin(1.05)*1.15],%[fx:$y+$r*cos(1.05)*1.15] %[fx:$x-$r*sin(1.05)*1.15],%[fx:$y-$r*cos(1.05)*1.15] %[fx:$x-$r*sin(0.45)*1.15],%[fx:$y-$r*cos(1.05)*1.15]"
                ;;
            #Diamond
            5) geometry="polygon %[fx:$x+$r*0.8],$y $x,%[fx:$y+$r*1.15] %[fx:$x-$r*0.8],$y $x,%[fx:$y-$r*1.15]"
                ;;
            #Star
            6) geometry="polygon $x,%[fx:$y-$r*1.1] %[fx:$x+$r*cos(0.9)*0.5],%[fx:$y-$r*sin(0.9)*0.5] %[fx:$x+$r*cos(0.333)*1.1],%[fx:$y-$r*sin(0.333)*1.1] %[fx:$x+$r*cos(0.333)*0.5],%[fx:$y+$r*sin(0.333)*0.5]  %[fx:$x+$r*cos(0.9)*1.1],%[fx:$y+$r*sin(0.9)*1.1] $x,%[fx:$y+$r*0.5] %[fx:$x-$r*cos(0.9)*1.1],%[fx:$y+$r*sin(0.9)*1.1] %[fx:$x-$r*cos(0.333)*0.5],%[fx:$y+$r*sin(0.333)*0.5] %[fx:$x-$r*cos(0.333)*1.1],%[fx:$y-$r*sin(0.333)*1.1] %[fx:$x-$r*cos(0.9)*0.5],%[fx:$y-$r*sin(0.9)*0.5]"
                ;;
            #Pill
            7) geometry="roundRectangle %[fx:$x-$r*0.5],%[fx:$y-$r] %[fx:$x+$r*0.5],%[fx:$y+$r] $r,%[fx:3*$r/7]"
                ;;
        esac

        color=$( bc <<< "$player-(8*($player/8))" )

        case $color in
            0) render_blue="${render_blue} $geometry";;
            1) render_sky="${render_sky} $geometry";;
            2) render_green="${render_green} $geometry";;
            3) render_yellow="${render_yellow} $geometry";;
            4) render_orange="${render_orange} $geometry";;
            5) render_red="${render_red} $geometry";;
            6) render_pink="${render_pink} $geometry";;
            7) render_violet="${render_violet} $geometry";;
        esac

        team=${players["$player"]}
        team_stars["$team"]="${team_stars["$team"]} ${x}x${y}"

    fi
    stars_done=$(( stars_done + 1 ))
    [ $log ] && echo -e "\rStar:${x}x${y} | Shape:$shape | Color:$color | Team:$team"
done < <(
    jq -r ' .scanning_data.stars|
            .[]                 |
        "\(.x) \(.y) \(.puid)"'\
        $dump_file;
        )
echo

echo -n "Drawing map..."
magick -size $(($unit*$units_x))x$(($unit*$units_y))\
    xc:black                                        \
    -fill   none                                    \
    -strokewidth 2                                  \
    -stroke "#4B403E" -draw "$render_white"         \
    -stroke "#0433FB" -draw "$render_blue"          \
    -stroke "#009DDC" -draw "$render_sky"           \
    -stroke "#35B303" -draw "$render_green"         \
    -stroke "#FBBB0F" -draw "$render_yellow"        \
    -stroke "#E16200" -draw "$render_orange"        \
    -stroke "#C11A00" -draw "$render_red"           \
    -stroke "#C12EBF" -draw "$render_pink"          \
    -stroke "#6127C4" -draw "$render_violet"        \
    ${output_file:-output.png} &&                   \
    echo "Done"


total=$( bc <<< "(($unit * ($unit_x - 2))/($unit/2)) * (($unit * ($unit_y - 2))/($unit/2)) * $stars_total * ${#teams}" )
for x_sqw in $( seq $unit $(( $unit / 2 )) $(( $unit * ( $units_x -1 ) )) ); do
    for y_sqw in $( seq $unit $(( $unit / 2 )) $(( $unit * ( $units_y -1) )) ); do
        don=$(( $don + 1 ))

        for team in ${teams[@]}; do
            echo -en "\rCalculating areas:$don/$total Team=$team"
            point_value[$team]=0
            stars=${team_stars[$team]}
            for star in ${stars[@]}; do
                x=$(cut -f 1 -d x <<< $star)
                y=$(cut -f 2 -d x <<< $star)
                point_value[$team]=$( bc <<< \
                "scale=4
                ${point_value[$team]} + 1/sqrt(($x_sqw-$x)^2 + ($y_sqw-$y)^2)"
                )
            done
        done
        higest=$(printf '%s\n' "${point_value[@]}" | sort -n | tail -n 1)
        claim=$( echo ${point_value[@]/$higest//} | cut -d/ -f1 | wc -w )

        magick "${output_file:-output.png}"     \
            -stroke "${teams_color[$claim]}"    \
            -fill   "${teams_color[$claim]}"    \
            -draw "rectangle $(($x_sqw -3)),$(($y_sqw -3)) $(($x_sqw +3)),$(($y_sqw +3))" \
            ${output_file:-output.png} &&       \
            echo -e "\r${x_sqw}x${y_sqw} - ${teams[$claim]}"

    done
done
