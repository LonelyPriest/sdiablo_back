#! /bin/bash

SQLS=""

for rsn in M-4-S-18-R-1858 M-4-S-18-R-1859 M-4-S-18-R-1860 M-4-S-18-R-1861 M-4-S-18-R-1862 \
M-4-S-18-R-1863 M-4-S-18-R-1864 M-4-S-18-R-1865 M-4-S-18-R-1866 M-4-S-18-R-1867 M-4-S-18-R-1868 \
M-4-S-18-R-1869 M-4-S-18-R-1870 M-4-S-18-R-1871 M-4-S-18-R-1872 M-4-S-18-R-1873 M-4-S-18-R-1874
do
    SQL1=$(echo update w_inventory_amount a inner join\(\
select style_number, brand, color, size, total from w_sale_detail_amount where rsn=\'${rsn}\'\) b \
on a.style_number=b.style_number and a.brand=b.brand \
and a.size=b.size and a.color=b.color set a.total=a.total+b.total \
where a.merchant=4 and a.shop=18)

    SQL2=$(echo update w_inventory a inner join\(\
select style_number, brand, total from w_sale_detail where rsn=\'${rsn}\'\) b \
	on a.style_number=b.style_number and a.brand=b.brand set a.amount=a.amount+b.total \
	where a.merchant=4 and a.shop=18)

    SQL3=$(echo delete from w_sale_detail_amount where rsn=\'${rsn}\')
    SQL4=$(echo delete from w_sale_detail where rsn=\'${rsn}\')
    SQL5=$(echo delete from w_sale where rsn=\'${rsn}\')
    
    SQLS=$(echo ${SQLS}${SQL1}\;${SQL2}\;${SQL3}\;${SQL4}\;${SQL5}\;)
done

echo $SQLS > mm.sql
