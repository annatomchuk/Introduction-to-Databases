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
insert into Patients (PatientID, PatientName, MedicalNotes, Phone)
select
    id,
    'Patient Name ' || id as PatientName,
    'Need to check medical records ' || id as MedicalNotes,
    '+38097' || (1000000 + id) as Phone
from generate_series(1, 500) as id;

insert into Doctors (DoctorID, DoctorName, Phone, Room, Speciality)
select
    id,
    'Doctor Name ' || id as DoctorName,
    '+38050' || (2000000 + id) as Phone,
    (100 + (id % 400)) as Room,
    (array[
        'Therapist', 'Cardiolog', 'Okylist', 'Psychology', 'Surgeon',
        'Neurologist', 'Dermatologist', 'Pediatrician', 'Traumatologist', 'Gastroenterologist'
    ])[1 + (id % 10)] as Speciality
from generate_series(1, 100) as id;

insert into Diagnosis (DiagnosID, Diagnos, Description) values
(1000, 'Heachache', 'Acute pain in the frontal lobe of the head'),
(2000, 'Heart Arytmia', 'Irregular heart rhythm detected during ECG'),
(3000, 'Epilepsia', 'Central nervous system neurological disorder'),
(4000, 'Chuma Disease', 'Rare dangerous bacterial infectious disease'),
(5000, 'Covid-19', 'Acute respiratory viral infection (SARS-CoV-2)'),
(6000, 'Gastritis', 'Inflammation of the protective lining of the stomach'),
(7000, 'Allergy', 'Hypersensitivity of the immune system to environmental factors'),
(8000, 'Bronchitis', 'Inflammation of the lining of bronchial tubes'),
(9000, 'Scoliosis', 'Sideways curvature of the spine'),
(10000, 'Dermatitis', 'Common skin irritation and inflammation condition');

insert into Appointments (AppointmentID, PatientID, DoctorID, DiagnosID, Date)
select
    id,
    (1 + (id % 500)) as PatientID,
    (1 + (id % 100)) as DoctorID,
    (1000 + ((id % 10) * 1000)) as DiagnosID,
    ('2026-01-01'::date + (id % 200) * '1 day'::interval)::date as Date
from generate_series(1, 10000) as id;

insert into Procedure (ProcedureID, AppointmentID, Description, Room, Price)
select
    id,
    id as AppointmentID,
    (ARRAY[
        'Therapia session', 'Psychological test', 'General body checking', 'Cardio check', 'Massage',
        'Blood test analyses', 'X-Ray screening', 'MRI Scan', 'Ultrasound scan', 'Endoscopy exam'
    ])[1 + (id % 10)] as Description,
    (100 + (id % 300)) as Room,
    (100 + (id % 1500)) as Price
from generate_series(1, 10000) as id;

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
where f.PriceCategory='expensive procedure' --фільтрую по вартості процедури, щоб вивело лише дорогі--
group by p.PatientName, d.DoctorName, ds.Diagnos, f.PriceCategory
order by "Total price" desc; --сортування по total price у спаданні--