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