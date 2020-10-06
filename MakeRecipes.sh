#!/bin/bash
#
#
#  A utility helper script to make a new set of PatchBot recipes from templates
#
#  A click saver…
#  Takes an Application Name (with spaces)
#  Assumes the name for the package is the App name with no spaces, opportunity
#  to provide an alternative
#  Makes a new directory for the recipes
#  Inserts the App Name and AppName variants into the recipes' placeholders
#  names the files, and is done
#
# parameters
# 1: pkg recipe identifier, for updating recipes' parent
parent_pkg_recipe_id="$1"


# the recipe repo directory is the container for this script
# and any application recipes folders, which contain their recipes
recipe_container_dir=$(dirname "$0")


# the templates subdirectory is adjacent to this script, the following folder
patchbot_templates_dir="PatchBot_Templates"



## MAIN

# ask for the app name
read -p "Application Name (Patch Definition and Patch Policy names): " app_name

# often the package is also
# the app name w/o spaces
pkg_name=${app_name// /}

# ask for the pkg name, w/ default
read -p "Package Name (no extension or spaces) [$pkg_name]: " this_input
if [ "$this_input" != "" ]
then
  pkg_name="$this_input"
fi

# lowercase string of pkg name
pkg_name_lc=$(awk '{print tolower($0)}' <<< "$pkg_name")

echo "Using..."
echo "App: $app_name"
echo "Pkg: $pkg_name"
echo "pkg: $pkg_name_lc"



## make a new directory to contain the application recipes?
echo "Application directory will be: $recipe_container_dir/$pkg_name"
# if it exists, we'll warn… and continue.
if [ -e "$recipe_container_dir/$pkg_name" ]
then
  echo "WARN: The directory exists!"
else
  echo "Making a new application directory"
  mkdir -v "$recipe_container_dir/$pkg_name"
  if [ $? -gt 0 ]
  then
    echo "mkdir failed, exiting"
    exit -13
  fi
fi


## copy any templates into the new directory
echo "Copying templates"
# 
while IFS=$'\n' read template_file
do
  # for each file, check if it exists, if not we'll make it
  # the new file name
  ## replaces the template text "PackageName" with the pkg_name string
  new_file_name="${template_file/PackageName/$pkg_name}"
  
  # some reporting
  echo "Template: $recipe_container_dir/$pkg_name/$new_file_name"
  
  # does the new file exist?
  if [ -e "$recipe_container_dir/$pkg_name/$new_file_name" ]
  then
    # file already there, skipping
    echo "WARN: file exists, skipping"
    #continue
  else
    # no file yet, let's make it
    cp "$recipe_container_dir/$patchbot_templates_dir/$template_file" "$recipe_container_dir/$pkg_name/$new_file_name"
    
    # replace variable placeholders with strings
    # {Application Name} -> app_name
    # {PackageName} -> pkg_name
    # {packagename} -> pkg_name_lc
    # edit in place, the new file/copy
    sed -e "s/{Application Name}/$app_name/g" \
		-e "s/{PackageName}/$pkg_name/g" \
		-e "s/{packagename}/$pkg_name_lc/g" \
		-i "" "$recipe_container_dir/$pkg_name/$new_file_name"
    
    # replace the identifier, if provided
    # {Pkg Recipe Identifier} -> parent_pkg_recipe_id
    if [ "$parent_pkg_recipe_id" ]
    then
      sed -e "s/{Pkg Recipe Identifier}/$parent_pkg_recipe_id/g" \
      -i "" "$recipe_container_dir/$pkg_name/$new_file_name"
    fi
    
    # replace the templaterecipe extension with recipe
    mv "$recipe_container_dir/$pkg_name/$new_file_name" "$recipe_container_dir/$pkg_name/${new_file_name/.templaterecipe/.recipe}"
    
  fi
done < <(
  ## list of files in the template directory
  ls -1 "$recipe_container_dir/$patchbot_templates_dir"
)

exit


