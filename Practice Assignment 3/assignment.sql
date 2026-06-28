create table customers (
    customer_id serial primary key,
    full_name varchar(100) not null,
    email varchar(100) unique not null,
    balance numeric(10,2) default 0
);

create table products (
    product_id serial primary key,
    product_name varchar(100) not null,
    price numeric(10,2) not null,
    stock_quantity int not null
);

create table orders (
    order_id serial primary key,
    customer_id int references customers(customer_id),
    order_date timestamp default current_timestamp,
    total_amount numeric(10,2) default 0
);

create table order_items (
    order_item_id serial primary key,
    order_id int references orders(order_id),
    product_id int references products(product_id),
    quantity int not null,
    price numeric(10,2) not null
);

create table order_log (
    log_id serial primary key,
    order_id int,
    customer_id int,
    action varchar(50),
    log_date timestamp default current_timestamp
);

create or replace function calculate_order_total(p_order_id int)
returns numeric(10,2)
language plpgsql
as $$
declare
	total numeric(10,2);
begin
	select coalesce(sum(quantity*price),0)
	into total
	from order_items
	where order_id=p_order_id;
	return total;
end;
$$;

create or replace procedure create_order(p_customer_id int)
language plpgsql
as $$
declare
	customer_exist boolean;
begin
	select exists(
		select *
		from customers
		where customer_id=p_customer_id)
		into customer_exist;
	if customer_exist then
		insert into orders(customer_id, order_date, total_amount)
		values(p_customer_id, current_timestamp, 0.00);
	else
		null;
	end if;
end;
$$;

create or replace procedure add_product_to_order(p_order_id int, p_product_id int, p_quantity int)
language plpgsql
as $$
declare
	pr_price numeric(10,2);
	pr_stock int;
begin
	if p_quantity<=0 then
		null;
	else
			select price, stock_quantity
			into pr_price, pr_stock
			from products
			where product_id=p_product_id;
			if pr_stock>=p_quantity then
				update products
				set stock_quantity=stock_quantity-p_quantity
				where product_id=p_product_id;
				insert into order_items(order_id, product_id, quantity, price)
				values(p_order_id, p_product_id, p_quantity, pr_price);
			else
				null;
			end if;
	end if;
end;
$$;

create or replace function triger_4()
returns trigger as $$
declare
	tr_order_id int;
begin
	if tg_option='DELETE' then
		tr_order_id:=old.order_id;
	else
		tr_order_id:=new.order_id;
	end if;
	update orders
	set total_amount=calculate_order_total(tr_order_id)
	where order_id=tr_order_id;
	return null;
end;
$$ language plpgsql;
create trigger triger_4
after insert or update or delete on order_items
for each row
execute function triger_4();

create or replace function triger_5()
returns trigger as $$
begin
	insert into order_log(order_id, customer_id, action, log_date)
	values(new.order_id, new.customer_id, 'ORDER_CREATED', current_timestamp);
	return null;
end;
$$ language plpgsql;
create trigger triger_5
after insert on orders
for each row
execute function triger_5();


insert into customers(full_name, email, balance)
values('Anna', 'anna.tomchuk@gmail.com', 1000000.00);
insert into products(product_name, price, stock_quantity)
values('CARRR', '13000.00', 5);
select*
from customers;
select *
from products;
call create_order(1);
select*
from orders
where customer_id=1;
select *
from order_log;
call add_product_to_order(1,1,2);
select*
from orders
where order_id=1;
select*
from products
where product_id=1;
select*
from order_items
where order_id=1;