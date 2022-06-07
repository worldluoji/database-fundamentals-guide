create table ORDER_DMEO (
	id int(11) not null primary key auto_increment,
	order_no varchar(36),
	receiver varchar(24),
	sender varchar(24)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
alter table ORDER_DMEO add index order_no_index(order_no)

drop procedure idata;
delimiter ;;
create procedure idata()
begin
  declare i int;
  set i=1;
  while(i<=12000)do
    insert into ORDER_DMEO(order_no,receiver,sender) values(i, i, i);
    set i=i+1;
  end while;
end;;
delimiter ;
call idata();
