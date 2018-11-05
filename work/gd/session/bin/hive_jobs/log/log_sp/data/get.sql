select req['city'],count(1) as freq from log_session.log_sp_raw 
	where dt=20140616 and req['city'] is not null
	group by req['city']
	order by freq desc
	;
