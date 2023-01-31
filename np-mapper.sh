#! /bin/bash
game_number=0000000000000000
code=FFFFFF
unit=100 # > 80
r_star=$(bc <<< "sqrt($unit)-6")
r_main=$(( $r_star*2 ))


curl https://np.ironhelmet.com/api  \
    -X POST                         \
    -d game_number=$game_number     \
    -d code=$code                   \
    -d api_version=0.1              \
    > dump.json || exit 1

echo  "What teams there are?"
read -a teams

for team in ${teams[@]}; do
    echo  "Who belongs to team $team?"
    read -a players_entered
    for player in ${players_entered[@]}; do
        players["$player"]="$team"
    done
done

cords=$(jq -r '.scanning_data.stars|.[]|.x' dump.json | sort -h)
stars_total=$( wc -l <<< $cords)
min_cord=$(head -n 1 <<< $cords)
max_cord=$(tail -n 1 <<< $cords)
units_x=$( bc <<< "($min_cord*-1+$max_cord+2.5)/1" )
home_x=$(  bc <<< "$units_x - $max_cord -2" )

cords=$(jq -r '.scanning_data.stars|.[]|.y' dump.json | sort -h)
min_cord=$(head -n 1 <<< $cords)
max_cord=$(tail -n 1 <<< $cords)
units_y=$( bc <<< "($min_cord*-1+$max_cord+2.5)/1" )
home_y=$(  bc <<< "$units_y - $max_cord -2" )
echo "Grid:${units_x}x${units_y}"
echo "Estimated home: ${home_x}x${home_y}"

while read x y player; do
    echo -en "\rProgress:$stars_done/$stars_total"
    x=$( bc <<< "(( $x + $home_x ) * $unit + $unit.5)/1" )
    y=$( bc <<< "(( $y + $home_y ) * $unit + $unit.5)/1" )
    #echo -ne "\rStar:${x}x${y}|"
    r=$r_star
    render_white="${render_white} circle $x,$y $(($x+$r)),$y"
    if [ ! $player = -1 ]; then
        shape=$( bc <<< "$player/8" )
        #echo -n "Shape:$shape|"
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
        #echo "Color:$color"
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
    #break
    stars_done=$(( stars_done + 1 ))
    #echo -e "\rStar:${x}x${y} | Shape:$shape | Color:$color | Team:$team"
done < <(
    jq -r ' .scanning_data.stars|
        .[]                     |
        "\(.x) \(.y) \(.puid)"'\
        dump.json;
        )
echo

echo "Generating map..."
magick -size $(( $unit * $units_x))x$(( $unit*$units_y ))              \
    xc:black                                    \
    -fill   none                                \
    -strokewidth 2                              \
    -stroke "#4B403E" -draw "$render_white"     \
    -stroke "#0433FB" -draw "$render_blue"      \
    -stroke "#009DDC" -draw "$render_sky"       \
    -stroke "#35B303" -draw "$render_green"     \
    -stroke "#FBBB0F" -draw "$render_yellow"    \
    -stroke "#E16200" -draw "$render_orange"    \
    -stroke "#C11A00" -draw "$render_red"       \
    -stroke "#C12EBF" -draw "$render_pink"      \
    -stroke "#6127C4" -draw "$render_violet"    \
    output.png

exit #This does not work anyway
for team in ${teams[@]}; do
    echo "Compiling team $team..."
    stars=( ${team_stars[$team]} )
    for star in ${stars[@]}; do
        x=$(cut -f 1 -d x <<< $star)
        y=$(cut -f 2 -d x <<< $star)
        echo "$x | $y"
        magick output.png              \
              -draw pixel           \
              -fx "Xi=i-$x; Yj=j-$y; 1.2*(0.5-hypot(Xi,Yj)/70.0)+0.5" \
        output.png
        echo --
    done

done
