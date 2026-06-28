--Таблички лектора--
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

--Task 1--
create or replace function calculate_order_total(p_order_id int) --Створення функції для обрахунку суми замовлень--
returns numeric(10,2)
language plpgsql
as $$
declare
	total numeric(10,2);
begin
	select coalesce(sum(quantity*price),0) --Якщо замовлення має продукти, то суму знаходжу як quantity*price, інакше повертаю 0--
	into total
	from order_items
	where order_id=p_order_id;--ID замовлення має дорівнювати ID функції--
	return total; --Повертаємо загальне--
end;
$$;
--Task 2--
create or replace procedure create_order(p_customer_id int) --Функція для створення нового замовлення--
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
		insert into orders(customer_id, order_date, total_amount) --Якщо користувач існує, то створюємо його замовлення і додаємо всю інформацію--
		values(p_customer_id, current_timestamp, 0.00);
	else
		null;--Якщо не існує, то просто нуль--
	end if;
end;
$$;
--Task 3--
create or replace procedure add_product_to_order(p_order_id int, p_product_id int, p_quantity int)--Створюю процедуру для додавання продукту в замовлення--
language plpgsql
as $$
declare
	pr_price numeric(10,2);
	pr_stock int;
begin
	if p_quantity<=0 then --Якщо кількість продуктів від'ємна чи нульова, то просто нуль--
		null;
	else
			select price, stock_quantity--Інакше обираємо ціну і кількість--
			into pr_price, pr_stock
			from products
			where product_id=p_product_id;--Перевіряю по ID--
			if pr_stock>=p_quantity then --Якщо кількість на залишках більша ніж ми замовляємо, то--
				update products
				set stock_quantity=stock_quantity-p_quantity--Тоді оновлюємо кількість, як загальну - куплену--
				where product_id=p_product_id;
				insert into order_items(order_id, product_id, quantity, price)--Вставка в таблицю order_items нової інформаціїї--
				values(p_order_id, p_product_id, p_quantity, pr_price);
			else
				null;--Якщо кількість на складі менша ніж хочемо купити, то нуль--
			end if;
	end if;
end;
$$;
--Task 4--
create or replace function triger_4() --Створення тригеру для автоматичного підрахунку вартості, коли змінюються дані--
returns trigger as $$
declare
	tr_order_id int;--В цій змінні буде зберігатись ID--
begin
	if tg_op='DELETE' then --Тут починаємо перевіряти рядки, якщо було видалено товар--
		tr_order_id:=old.order_id;--То ID старе треба брати--
	else
		tr_order_id:=new.order_id;--Якщо були інші дії виконані, то беремо нове ID--
	end if;
	update orders
	set total_amount=calculate_order_total(tr_order_id)--Виклик функції з Task 1 щоб перерахувала суму--
	where order_id=tr_order_id;
	return null;
end;
$$ language plpgsql;
create trigger triger_4 --Створюю тригер--
after insert or update or delete on order_items --Він буде спрацьовувати коли буде видалення, оновлення, вставка в таблицю order_items--
for each row
execute function triger_4();--Запуск функції--
--Task 5--
create or replace function triger_5()--Створення тригеру для записів у таблицю order_log після того як нове замовлення створюється--
returns trigger as $$
begin
	insert into order_log(order_id, customer_id, action, log_date)--Вставка в таблицю у ці колонки--
	values(new.order_id, new.customer_id, 'ORDER_CREATED', current_timestamp);--Тут вставляємо значення ID замовлення і користувача, потім одразу всім однаковий статус і точний час--
	return null;
end;
$$ language plpgsql;
create trigger triger_5
after insert on orders --Після вставки в orders зразу починає виконуватись тригер--
for each row
execute function triger_5();--Запуск функції з Task5--
--Task 6--
insert into customers(full_name, email, balance)
values('Anna', 'anna.tomchuk@gmail.com', 1000000.00);--Заповнююю customers своїми новими даними для тесту--
insert into products(product_name, price, stock_quantity)
values('CARRR', '13000.00', 5);--Так само з таблицею products--
select*
from customers;--Обираю всі дані з customers--
select *
from products;
call create_order(5);--Виклик функції з 2 завдання, щоб створити замовлення--
select*
from orders
where customer_id=5;--Customer_id =5, тобто зразу з новими даними певревіряю--
select *
from order_log;--Тут має спрацювати Task 5 тригер зі створенням замовлення в order_log--
call add_product_to_order(5,5,1);--З Task 3 додаємо товар в замовлення 5 ID, 5 ID, 1 quantity--
select*
from orders
where order_id=5;--Тут обираємо наш ID=5 і після покупки сума має змінитись на суму замовлення--
select*
from products
where product_id=5;--тут перевіряю чи кількість на складі змінилась--
select*
from order_items
where order_id=5;--Тут має змінитись кошик замолвення--