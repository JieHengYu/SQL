CREATE TABLE zoo (animal_id bigserial,
                  animal_name varchar(50),
			      domain_ varchar(25),
			      kingdom_ varchar(25),
			      phylum_ varchar(25),
			      class_ varchar(25),
			      order_ varchar(25),
			      family_ varchar(25),
			      genus_ varchar(25),
			      species_ varchar(50));

INSERT INTO zoo (animal_name, domain_, kingdom_,
                 phylum_, class_, order_, family_,
				 genus_, species_)
VALUES ('Amur Leopard', 'Eukaryote', 'Animal', 
        'Chordate', 'Mammal', 'Carnivora', 'Felidae', 
		'Panthera', 'Panthera pardus orientalis'),
       ('Anaconda', 'Eukaryote', 'Animal', 'Chordate',
	    'Reptile', 'Squamata', 'Boidae', 'Eunectes',
		'Boa murina'),
	   ('Bee-eater', 'Eukaryote', 'Animal', 
	    'Chordate', 'Aves', 'Coraciform', 'Meropidae',
		'Merop', 'Merops apiaster'),
	   ('Bonobo', 'Eukaryote', 'Animal', 'Chordate',
	    'Mammal', 'Primate', 'Hominidae', 'Pan',
		'Pan paniscus'),
       ('Camel', 'Eukaryote', 'Animal', 'Chordate',
	    'Mammal', 'Artiodactyl', 'Camelidae',
		'Camelus', 'Camelus dromedarius'),
	   ('Capybara', 'Eukaryote', 'Animal', 'Chordate',
	    'Mammal', 'Rodent', 'Caviidae', 
		'Hydrochoerus', 'Hydrochoerus hydrochaeris'),
	   ('Dung Beetle', 'Eukaryote', 'Animal', 
	    'Chordate', 'Arthorpod', 'Insect', 
		'Coleoptera', 'Scarabaeoid', NULL),
       ('Galapagos Tortoise', 'Eukaryote', 'Animal',
	    'Chordate', 'Reptile', 'Testudine', 
		'Testudinidae', 'Chelonoidis', 
		'Chelonoidis niger'),
	   ('Grizzly Bear', 'Eukaryote', 'Animal', 
	    'Chordate', 'Mammal', 'Ursidae', 'Ursus',
		'Ursus arctos', 'Ursus arctos horribilis'),
	   ('Harpy Eagle', 'Eukaryote', 'Animal', 
	    'Chordate', 'Aves', 'Accipitriform', 
		'Accipitridae', 'Harpia', 'Haripia harpyja'),
       ('King Cobra', 'Eukaryote', 'Animal', 
	    'Chordate', 'Reptile', 'Squamata', 'Elapidae',
		'Ophiophagus', 'Ophiophagus hannah'),
	   ('Klipspringer', 'Eukaryote', 'Animal',
	    'Chordate', 'Mammal', 'Artiodactyl',
		'Bovidae', 'Oreotragus', 
		'Oreotragus oreotragus'),
	   ('Koala', 'Eukaryote', 'Animal', 'Chordate',
	    'Mammal', 'Diprotodont', 'Phascolarctid',
		'Phascolarctos', 'Phascolarctos cinereus'),
       ('Lemur', 'Eukaryote', 'Animal', 'Chordate',
	    'Primate', 'Lemuroid', NULL, NULL, NULL),
	   ('Red Panda', 'Eukaryote', 'Animal',
	    'Chordate', 'Mammal', 'Carnivora',
		'Ailuridae', 'Ailurus', 'Ailurus fulgens'),
	   ('Tapir', 'Eukaryote', 'Animal', 'Chordate',
		'Mammal', 'Perissodactyla', 'Tapiridae', 
		NULL, NULL),
	   ('Two-toed Sloth', 'Eukaryote', 'Animal',
		'Chordate', 'Mammal', 'Pilosa', 
		'Choloepodidae', 'Choloepus', NULL),
	   ('Zebra', 'Eukaryote', 'Animal', 'Chordate',
		'Mammal', 'Perissodactyl', 'Equidae', 
		'Equus', NULL);

SELECT * FROM zoo;











