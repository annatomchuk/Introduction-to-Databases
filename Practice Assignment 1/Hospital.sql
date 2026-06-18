create table Patients( ---створюю 5 різних таблиць--
    PatientID int primary key, --у всіх пацієнітв обов'язково має бути унікальне ID--
    PatientName varchar(100),
    MedicalNotes varchar(100),
    Phone varchar(20)
);
create table Doctors(
    DoctorID int primary key,
    DoctorName varchar(100),
    Phone varchar(20),
    Room int,
    Speciality varchar(100)
);
create table Diagnosis (
    DiagnosID int primary key,
    Diagnos varchar(100),
    Description varchar(100)
    );
create table Appointments (
    AppointmentID int primary key,
    PatientID int,
    DoctorID int,
    DiagnosID int,
    Date date
);
create table Procedure(
    ProcedureID int primary key,
    Description varchar(100),
    AppointmentID int,
    Room int,
    Price int
);
insert into Patients (PatientID, PatientName, MedicalNotes, Phone) values --наповнюю даними--
(1111, 'Olha Mork', 'Need to visit Main doctor', '380 986 234 103'),
(2222, 'Dmytro Bevz', 'Need to visit Therapist', '380 978 234 983'),
(3333, 'Kateryna Zelena', 'Need to visit Cardiolog', '380 999 544 244'),
(4444, 'Maria Chorna', 'Need to visit Okylist', '380 945 567 133'),
(5555, 'Oleh Wers', 'Need to visit Pscychology', '380 999 894 324');

insert into Doctors (DoctorID, DoctorName, Phone, Room, Speciality) values
(0001, 'Anna', '380 986 234 103', 111,'Main Doctor'),
(0002, 'Ostap', '380 926 275 123', 123,'Pscychology'),
(0003, 'Stepan', '380 906 232 109', 321,'Cardiolog'),
(0004, 'Kyrylo', '380 988 999 803', 212,'Okylist'),
(0005, 'Demian', '380 996 323 563', 108,'Therapist');

insert into Diagnosis (DiagnosID, Diagnos, Description) values
(1000, 'Heachache', 'Pain in a head'),
(2000, 'Heart', 'Arytmia'),
(3000, 'Epilepsia', 'Nerves'),
(4000, 'Chuma', 'Infection'),
(5000, 'Covid', 'Virus');

insert into Appointments (AppointmentID, PatientID, DoctorID, DiagnosID, Date) values
(1, 1111, 5, 5000,'2026-06-21'),
(2, 5555, 2,3000,'2026-06-30'),
(3, 2222, 1,1000,'2026-06-11'),
(4, 4444, 3,2000,'2026-07-01'),
(5, 3333, 4,4000,'2026-06-28'),
(6, 4444, 5,1000,'2026-08-01');

insert into Procedure(ProcedureID, Description, AppointmentID, Room,Price) values
(1001, 'Therapia', 1,321,250),
(2001, 'Psychological test',2, 123,500),
(3001, 'General checking',3, 123,1200),
(4001, 'Cardio check',4, 212,450),
(5001, 'Checking',5, 108,300),
(6001, 'Massage',6, 108,1300);

with filteredProcedure as ( --створюю CTE--
select
	ProcedureID,
	AppointmentID,
	Description,
	Price,
	case --аналог if/else фільтрую price--
		when Price>400 then 'expensive procedure'
		else 'econom procedure'
	end as PriceCategory --додаткова колонка після фільтрації, у ній буде результат сортування--
from Procedure
)
select
	p.PatientName,
	d.DoctorName,
	ds.Diagnos,
	f.PriceCategory,
	sum(f.Price) as "Total price" --через агрегатну функцію виводжу вартість у нову колонку--
from Appointments a
join Patients p on a.PatientID=p.PatientID --об'єдную пацієнтів з двох таблиць по ID--
join Doctors d on a.DoctorID=d.DoctorID
join Diagnosis ds on a.DiagnosID=ds.DiagnosID
join filteredProcedure f on a.AppointmentID =f.AppointmentID --CTE об'єдную з таблицею Appointment--
where a.Date>='2026-06-01' --фільтрую по даті, все що було після 01.06--
group by p.PatientName, d.DoctorName, ds.Diagnos, f.PriceCategory
order by "Total price" desc; --сортування по total price у спаданні--