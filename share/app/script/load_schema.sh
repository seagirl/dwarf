base=${0%/*}/..
lib=${base}/lib
app=${base}/cli.psgi

rm ${lib}/App/DB/Schema.pm
perl -I $lib $app cli load_schema > ${lib}/App/DB/Schema.pm.$$
mv ${lib}/App/DB/Schema.pm.$$ ${lib}/App/DB/Schema.pm
