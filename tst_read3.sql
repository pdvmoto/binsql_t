

select /*+ full(t) parallel(t,2) */          count (*) from t t ;

select /*+ full(t) parallel(t,2) */  active, count (*) from t t group by active ;  

select /*+ full(t) parallel(t,2) */          count (*) from cpt t ;

select /*+ full(t) parallel(t,2) */  active, count (*) from cpt t group by active ;  

select /*+ full(t) parallel(t,2) */          count (*) from t t ;

select /*+ full(t) parallel(t,2) */  active, count (*) from t t group by active ;  

select /*+ full(t) parallel(t,2) */          count (*) from cpt t ;

select /*+ full(t) parallel(t,2) */  active, count (*) from cpt t group by active ;  

@tst_read3 
