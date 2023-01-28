with
partitioned as (
  select
    file_md5,
	load_dt,
    row_number() over(partition by file_md5
                      order by load_dt desc
                      ) as row_number
  from cs.lnd_okta_user
),

most_recent as (
  select file_md5, load_dt
    from partitioned
   where row_number = 1
)

select blobs.*
  from cs.lnd_okta_user blobs,
       most_recent
 where blobs.load_dt = most_recent.load_dt
