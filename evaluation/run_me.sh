#!/bin/sh



# printing out 
# defaul dir "work/*.html"
./tools/get_tables_from_iwptRes.pl coarse 
./tools/get_tables_from_iwptRes.pl fine   

./tools/get_tables_from_iwptRes.pl coarse "work_unoff/*.html"
./tools/get_tables_from_iwptRes.pl fine   "work_unoff/*.html"


for OFF in official unofficial ; do
  for TYPE in coarse fine ; do  
	putW ${TYPE}_IWPT_SharedTask_${OFF}_results.html #putW put stuff in my webpage, replace with something else
	cp    ${TYPE}_IWPT_SharedTask_${OFF}_results.html ../../
	# note that github doesn't seem to support google charts (generated pages don't work from there)
	git add ../../${TYPE}_IWPT_SharedTask_${OFF}_results.html
	git commit -m "update res" ../../${TYPE}_IWPT_SharedTask_${OFF}_results.html
	open ${TYPE}_IWPT_SharedTask_${OFF}_results.html 
  done
done

OLDPWD=`pwd`
cd ../..
git push 
cd $OLDPWD


