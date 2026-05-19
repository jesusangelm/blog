+++
title = "Principios SOLID en Ruby"
date = 2024-11-08
draft = false
tags = ['programacion', 'solid', 'ruby']
description = "Ejemplos sencillos de los Principios SOLID en Ruby"
+++

Del artículo en la Wikipedia:

> En ingeniería de software, SOLID (Single responsibility, Open-closed, Liskov substitution, Interface segregation and Dependency inversion) es un acrónimo mnemónico introducido por Robert C. Martin a comienzos de la década del 2000 que representa cinco principios básicos de la programación orientada a objetos y el diseño. Cuando estos principios se aplican en conjunto es más probable que un desarrollador cree un sistema que sea fácil de mantener y ampliar con el tiempo. Los principios SOLID son guías que pueden ser aplicadas en el desarrollo de software para eliminar malos diseños provocando que el programador tenga que refactorizar el código fuente hasta que sea legible y extensible. Puede ser utilizado con el desarrollo guiado por pruebas, y forma parte de la estrategia global del desarrollo ágil de software y desarrollo adaptativo de software. 

Los Principios S.O.L.I.D nos pueden ayudar a escribir código legible, mucho
más mantenible, organizado y altamente adaptable. Además de ayudarnos a que 
este no sea tan propenso a fallos o bugs cuando se modifican comportamientos
del código.

Cabe destacar que muchas de las soluciones que nos indican los principios SOLID hacen
uso de interfaces, pero dado que Ruby no cuenta con interfaces como tal, usaremos módulos
para simular dichas interfaces.

# Single Responsability Principle (Principio de Responsabilidad Única):

Este principio nos dice:

> Una clase sólo debe tener una razón para cambiar.

La idea que nos transmite este principio es que nuestras clases solo deben
tener una y solo una responsabilidad de la funcionalidad que esta proporciona
al software, haciendo esto lograremos que nuestra clase solo requiera ser
modificada únicamente cuando deban realizarse ajustes o cambios en las
funcionalidades que ella ofrece y de las cuales es responsable.
Una clase no debería contener funcionalidades o responsabilidades que no le
competen, ya que al momento de requerir hacer cambios en estas funcionalidades
corremos el riesgo de que rompamos la funcionalidad deseada de la clase.

Veamos esto con un ejemplo sencillo.

**El problema:**

Lenguaje: **Ruby**

```ruby {linenos=table,anchorlinenos=true}
# bad_employee.rb
class Employee
  attr_reader :name

  # La clase Employee solo deberia de ocuparse de gestionar
  # los datos de un empleado, en este ejemplo: los metodos acontinuacion
  # encajan con lo que deberia hacer la clase.
  def initialize(name)
    @name = name
  end

  def say_name
    puts "My name is: #{@name}"
  end

  # El calculo de horas y/o generacion de reporte no deberia ser parte de esta clase
  # el formato de los reporte podria cambiar con el tiempo o
  # el calculo de horas. lo que haria que tengamos que venir a esta clase a hacer
  # cambios, que no son precisamente correspondientes a un empleado.
  # Aca estamos violando el principio de responsabilidad simple
  def show_time_sheet_report
    puts "This is the report for #{@name}"
  end
end

fulanita = Employee.new('Fulanita de tal')
fulanita.say_name
fulanita.show_time_sheet_report
```

Como podemos observar, la clase `Employee` se encarga de administrar empleados,
sin embargo, también se le ha dado la responsabilidad del cálculo de horas y reporte por
lo que se está incumpliendo con el Principio de Responsabilidad Única.

**La solución:**

El problema especificado por este principio suele sugerir la creación de clases adicionales
en la que podamos organizar mejor las responsabilidades y competencias de nuestro software,
por lo que acá la solución será crear una nueva clase llamada `TimeSheetReport` en donde
estará la lógica de cálculo de horas y reporte de los empleados.

Lenguaje: **Ruby**

```ruby {linenos=table,anchorlinenos=true}
# good_employee.rb
class Employee
  attr_reader :name

  # La clase empleado solo se ocupa de
  # la gestion de los datos del empleado
  def initialize(name)
    @name = name
  end

  def say_name
    puts "My name is: #{@name}"
  end
end

# Lo concerniente a los reportes se separan de la clase empleado
# original y se coloca en una clase propia la cual se encargara
# de lo relacionado a los reportes y horas.
class TimeSheetReport
  def show_report_from(employee)
    puts "This is the report for #{employee.name}"
  end
end

# de esta forma y separando las responsabilidades en clases dedicadas,
# cumplimos con el principio de responsabilidad simple.

fulanita = Employee.new('Fulanita de tal')
fulanita.say_name

report = TimeSheetReport.new
report.show_report_from(fulanita)
```

Con esto, cada clase tendrá solo una única responsabilidad, cumpliendo así
con el Principio de Responsabilidad Única.

# Open/Close Principle (Principio de Abierto/Cerrado):

Este principio nos dice:

> Las clases deben estar abiertas a la extensión pero cerradas a la modificación.

La idea que nos transmite este principio es simplemente la de evitar que nuestro código se rompa cuando
estamos implementando nuevas funcionalidades.

Las clases están abiertas a la extensión cuando puedes agregarle funcionalidades como nuevos métodos o campos, crear subclases, sobreescribir su comportamiento, etc.

Cuando una clase está completa, es de alto riesgo realizarle modificaciones,
ya que podríamos terminar rompiendo su comportamiento.
Es por eso que debemos preferir extenderla en lugar de modificarla.

Cabe destacar que no debemos aplicar este principio a todos los cambios de una clase, si una clase en específico
tiene un fallo o bug, debemos corregirlo de raíz, no debemos extenderla con clases nuevas que implementen la solución.
Los defectos de la clase padre no deben ser transmitidos a la clase hija.

Veamos esto con un ejemplo sencillo.

**El problema:**
Lenguaje: **Ruby**

```ruby {linenos=table,anchorlinenos=true}
# bad_order.rb
class Order
  def initialize(line_items, shipping)
    @line_items = line_items
    @shipping = shipping
  end

  # este metodo podria descomponerse si intento meter un nuevo metodo
  # de envio. Esta clase deberia estar abierta a la extencion pero
  # cerrada a la modificacion.
  def shipping_cost
    puts "ground shipping for #{@line_items} is 10USD" if @shipping == 'ground'

    return unless @shipping == 'air'

    puts "air shipping for #{@line_items} is 20USD"
  end
end

new_order_air = Order.new(%i[toy pc medicine], 'air')
new_order_ground = Order.new(%i[toy pc medicine], 'ground')
new_order_air.shipping_cost
new_order_ground.shipping_cost
``````

Esta clase está abierta a la extensión, pero también abierta a la modificación
ya que si necesitamos agregar una nueva forma de envío, vamos a tener 
que modificar el método `shipping_cost` en esta clase
arriesgándonos a descomponer su comportamiento.

**La solución:**

La solución a este problema suele realizarse con interfaces, en ellas
especificaremos métodos comunes entre las distintas formas de envíos, para que 
luego, cualquier forma de envío nueva a agregar, deba implementar los métodos
requeridos por la interfaz.

Lenguaje: **Ruby**

```ruby {linenos=table,anchorlinenos=true}
# good_order.rb

# interfaz shipping
module Shipping
  def cost
    raise NotImplementedError, 'cost method not implemented'
  end
end

# creamos clases que implementen el metodo que la clase
# Order realmente necesita.
# Cada nueva forma de envio debe implementar el metodo que requiere
# la interfaz Shipping.
class Air
  include Shipping

  def cost
    'cost is 20USD'
  end
end

class Ground
  include Shipping

  def cost
    'cost is 10USD'
  end
end

class Sea
  include Shipping

  def cost
    'cost is 15USD'
  end
end

class Order
  def initialize(line_items, shipping)
    @line_items = line_items
    @shipping = shipping
  end

  def shipping_cost
    puts "#{@shipping.class} shipping for #{@line_items} #{@shipping.cost}"
  end
end

# asi cumplimos el principio abierto/cerrado.
new_order_air = Order.new(%i[toy pc medicine], Air.new)
new_order_ground = Order.new(%i[toy pc medicine], Ground.new)
new_order_sea = Order.new(%i[genrator], Sea.new)
new_order_air.shipping_cost
new_order_ground.shipping_cost
new_order_sea.shipping_cost
``````

Como se puede observar, usando interfaces podemos definir reglas que deben cumplir las 
nuevas formas de envío. Esto nos permite poder extender la clase `Order` con nuevas
formas de envío sin necesidad de modificarla y reduciendo el riesgo de introducir 
fallos en el código.

Así estamos cumpliendo con el Principio de Abierto/Cerrado. La clase `Order`
está ahora abierta a la extensión (podemos agregar nuevas formas de envío)
pero cerrada a la modificación (agregamos nuevas formas de envío sin modificar la clase `Order`).

# Liskov Substitution Principle (Principio de substitución de Liskov):

Este principio nos dice:

> Al extender una clase, recuerda que debes tener la capacidad de pasar objetos de las subclases en lugar de objetos de la clase padre, sin descomponer el código cliente.

Acá la idea es que al crear clases hijas para extender,
una clase, padre, debemos asegurarnos de que dicha clase
hija, no esté heredando métodos o funcionalidades inútiles
que no le servirán o que no van a usar. Así como también
evitar realizar cambios de los comportamientos heredados
de la clase padre que puedan romper el código cliente.

Veamos esto con un ejemplo:

**El problema:**

Lenguaje: **Ruby**

```ruby {linenos=table,anchorlinenos=true}
# bad_document.rb

# clase padre
class Document
  def initialize(data, filename)
    @data = data
    @filename = filename
  end

  def open
    puts "Openning file #{@filename}"
  end

  def save
    puts "Saving data #{@data} in file #{@filename}"
  end
end

# clase hija
class ReadOnlyDocument < Document
  # un documento de solo lectura no deberia poder guardarse/modificarse
  # por lo que cambiamos el comportamiento base y agregamos una exepcion
  # si se intenta llamar a este metodo.
  def save
    raise 'Can not save a read-only document'
  end
end

# codigo cliente
class Project
  def initialize(documents)
    @documents = documents
  end

  def open_all
    puts 'starting openning proccess'
    @documents.each do |doc|
      doc.open
    end
  end

  def save_all
    # por desgracia, la clase hija ReadOnlyDocument
    # hara que nuestro cliente Project se rompa al
    # intentar guardar un documento de solo lectura
    # debido a la Exception agregada en el metodo save
    puts 'starting save proccess'
    @documents.each do |doc|
      doc.save
    end
  end
end
# esto hace que violemos el principio de substitucion de liskov
# ya que cuando estamos extendiendo una clase (herencia)
# la clase hija deberia agregar funcionalidades extras y necesarias
# que no estaban en la clase padre sin que se rompa el codigo cliente.
# NO debemos eliminar el comportamiento de la clase padre.
# y eso es justo lo que estamos haciendo en nuestra clase ReadOnlyDocument

testdoc = Document.new('prueba', 'prueba.txt')
ro_doc = ReadOnlyDocument.new('no escribible', 'ro.md')
document_list = [testdoc, ro_doc]

my_project = Project.new(document_list)
my_project.open_all
my_project.save_all
``````

Acá podemos observar que cuando extendemos la clase `Document` con la clase `ReadOnlyDocument` estamos
es modificando su comportamiento, ya que un documento de solo lectura no debería poder guardarse.
El problema acá es que hacer esto provoca que rompa nuestro código cliente debido a que al mismo
le es indiferente quién puede o no puede guardar.

Esto provoca que se incumpla el Principio de Sustitución de Liskov, ya que estamos obligando a la clase
hija a heredar funciones que esta no requiere o no va a usar, además de eso, dicha herencia de funcionalidades
inútiles provocan que se rompa la funcionalidad del código cliente.

**La solución:**

La solución a este problema es la reorganización de la jerarquía de clases. Una clase hija debe
extender el comportamiento de la clase padre, por lo que el documento de solo lectura
ahora debe ser el documento por defecto y estar en lo alto de la jerarquía, al ser este más genérico
debe contener solo las funcionalidades que realmente se requieren en un documento base.

Ya que `Document` sera de solo lectura por defecto, la forma de extenderlo correctamente sería
agregando la funcionalidad de escritura en una nueva clase que herede sus funciones base.

Lenguaje: **Ruby**

```ruby {linenos=table,anchorlinenos=true}
# good_document.rb

# clase padre
class Document
  # Ahora nuestra clase padre contiene el funcionamiento y caracteristicas
  # mas basicas y necesarias. esta es lo mas generica posible.
  def initialize(data, filename)
    @data = data
    @filename = filename
  end

  # por defecto un documento solo puede abrirse
  def open
    puts "Openning file #{@filename}"
  end
end

# clase hija
class WritableDocument < Document
  # dado que necesitamos poder editar/guardar documentos
  # extendemos la clase Document con la nueva funcionalidad
  # creando una clase hija WritableDocument
  def save
    puts "Saving data #{@data} in file #{@filename}"
  end
end

class Project
  def initialize(documents, writable_documents)
    @documents = documents
    @writable_documents = writable_documents
  end

  # por defecto todos los documentos se pueden abrir
  # asi que no vamos a tener inconvenientes aca.
  def open_all
    puts 'starting openning proccess'
    @documents.each do |doc|
      doc.open
    end
  end

  # Dado que el guardado/modificacion es exclusivo a WritableDocument
  # adaptamos el codigo cliente para que trabaje solo con documentos WritableDocument
  # para asi no romper el codigo.
  def save_all
    puts 'starting save proccess'
    @writable_documents.each do |wdoc|
      wdoc.save
    end
  end
end


testdoc = Document.new('ro doc', 'prueba.txt')
testdoc2 = Document.new('def doc', 'prueba2.txt')
wr_doc = WritableDocument.new('escribible', 'wr_doc.md')
wr_doc2 = WritableDocument.new('escribible 2', 'wr_doc2.md')
docs = [testdoc, testdoc2]
wrdocs = [wr_doc, wr_doc2]

my_project = Project.new(docs, wrdocs)
my_project.open_all
my_project.save_all
``````

Con esto cumplimos con el Principio de Sustitución de Liskov al organizar
correctamente la extensibilidad de las subclases.

# Interface Segregation Principle (Principio de Segregación de Interfaz):

Este principio nos dice:

> No se debe forzar a los clientes a depender de métodos que no utilizan.

Acá lo que este principio nos intenta transmitir es que debemos tratar de mantener nuestras interfaces lo más sencilla posible
y con únicamente los métodos que esta realmente necesita, para que así, al momento de que una clase, deba implementar alguna de
nuestras interfaces, no se vea obligada a implementar posibles métodos que esta no necesite o que no vaya a usar.

Si es necesario, podemos escribir múltiples interfaces con pocos métodos (segregación) en lugar de una interfaz con muchos métodos.

Cabe destacar que hay que buscar un equilibrio, tampoco debemos caer en la tentación de crear decenas o cientos de interfaces con muy pocos
métodos.

Veamos esto con un ejemplo:

**El problema:**

Lenguaje: **Ruby**

```ruby {linenos=table,anchorlinenos=true}
# bad_cloudprovider.rb

# Interface CloudProvider
module CloudProvider

  # todos los nuevos cloud provider
  # deben implementar estos metodos.
  def store_file(name)
    raise NotImplementedError, 'implementa el metodo store_file'
  end

  def show_file(name)
    raise NotImplementedError, 'implementa el metodo show_file'
  end

  def create_server(region)
    raise NotImplementedError, 'implementa el metodo create_server'
  end

  def list_servers(region)
    raise NotImplementedError, 'implementa el metodo list_servers'
  end

  def show_cdna_address
    raise NotImplementedError, 'implementa el metodo show_cdna_address'
  end
end

class Amazon
  include CloudProvider

  # Amazon los implementa todos
  def store_file(name)
    puts "#{self.class} is storing the file #{name}"
  end

  def show_file(name)
    puts "#{self.class} is showing the file #{name}"
  end

  def create_server(region)
    puts "#{self.class} is creating a new server in #{region} region"
  end

  def list_servers(region)
    puts "#{self.class} is listing all your server in #{region} region"
  end

  def show_cdna_address
    puts "#{self.class} is showing the CDNA Address"
  end
end

class Dropbox
  include CloudProvider

  # Pero Dropbox no cuenta con todas las funciones que exije la
  # interfaz, por lo que no los implementa todos, o los implementa
  # con codigo de relleno para no romper la interfaz, pero es no es una
  # solucion limpia.
  # los otros 3 metodos no son implementados ya que no se usan en
  # Dropbox.
  def store_file(name)
    puts "#{self} is storing the file #{name}"
  end

  def show_file(name)
    puts "#{self} is showing the file #{name}"
  end
end

aws = Amazon.new
aws.store_file('prueba.md')
aws.show_file('prueba.md')
aws.create_server('us-east-1')

drb = Dropbox.new
drb.store_file('document.docx')
drb.list_servers('us-east-1')
``````

Acá podemos ver que nuestra interfaz `CloudProvider` define 5 métodos que deben
ser implementados por cualquier nuevo proveedor cloud, en este caso las clases `Amazon` y `Dropbox`.

`Amazon` si cuenta con todos los servicios que sugieren los métodos de la interfaz `CloudProvider`, por lo 
tanto implementa todos sus métodos. Pero `Dropbox` solo puede ofrecer dos de los servicios especificados 
en la interfaz `CloudProvider` los cuales son, `store_file` y `show_file` por lo que estos son los únicos métodos
que la clase `Dropbox` implementa, dejando de lado los demás métodos.

Acá es donde incumplimos con el Principio de Segregación de Interfaces, ya que la clase `Dropbox` ahora debe
o dejar sin implementar los métodos que no usa o implementándolos a medias en un intento de satisfacer a la interfaz.

**La solución:**

Como el mismo nombre del principio indica, la mejor solución suele ser segregar (separar o dividir) la interfaz en partes.

Lenguaje: **Ruby**

```ruby {linenos=table,anchorlinenos=true}
# good_cloudprovider.rb

# El monton de metodos de nuestra gran interfaz ahora han sido
# segregados en interfaces mas acordes con las funciones que estos
# metodos proveen.
module CloudHostingProvider
  def create_server(region)
    raise NotImplementedError, 'implementa el metodo create_server'
  end

  def list_servers(region)
    raise NotImplementedError, 'implementa el metodo list_servers'
  end
end

module CdnProvider
  def show_cdna_address
    raise NotImplementedError, 'implementa el metodo show_cdna_address'
  end
end

module CloudStorageProvider
  def store_file(name)
    raise NotImplementedError, 'implementa el metodo store_file'
  end

  def show_file(name)
    raise NotImplementedError, 'implementa el metodo show_file'
  end
end

class Amazon
  # Amazon class ahora debe implementar las interfaces que realmente necesita
  include CloudHostingProvider
  include CdnProvider
  include CloudStorageProvider

  def store_file(name)
    puts "#{self.class} is storing the file #{name}"
  end

  def show_file(name)
    puts "#{self.class} is showing the file #{name}"
  end

  def create_server(region)
    puts "#{self.class} is creating a new server in #{region} region"
  end

  def list_servers(region)
    puts "#{self.class} is listing all your server in #{region} region"
  end

  def show_cdna_address
    puts "#{self.class} is showing the CDNA Address"
  end
end

class Dropbox
  # lo mismo para Dropbox, tan solo implementa la interfaz
  # que necesita.
  include CloudStorageProvider

  def store_file(name)
    puts "#{self.class} is storing the file #{name}"
  end

  def show_file(name)
    puts "#{self.class} is showing the file #{name}"
  end
end



aws = Amazon.new
aws.store_file('prueba.md')
aws.show_file('prueba.md')
aws.create_server('us-east-1')

drb = Dropbox.new
drb.store_file('document.docx')
``````

De esta forma cumplimos con el principio de segregación de interfaces
ya que ahora nuestras clases solo implementan las interfaces que contienen
los métodos que ellas realmente necesitan.

Las nuevas clases ya no están obligadas a implementar o depender de métodos inútiles para ellas.

# Dependency Inversion Principle (Principio de Inversión de Dependencia):

Este principio nos dice:

> Las clases de alto nivel no deben depender de clases de bajo nivel.
> Ambas deben depender de abstracciones (interfaces). Las abstracciones no deben
> depender de detalles. Los detalles deben depender de abstracciones.

Puede ser confuso ese enunciado, pero veámoslo de esta forma. Las clases de bajo nivel suelen ser nuestras clases que realizan
operaciones básicas como trabajar con un disco, transferir datos por la red, alguna conexión a una base de datos, etc.
Las clases de alto nivel suelen ser nuestras clases que llevan la lógica de negocio completa y que hacen uso de las clases
de bajo nivel.

Lo que este principio intenta transmitirnos es que, cuando hacemos nuestras
clases de alto nivel  dependientes de clases de bajo nivel, corremos el
riesgo de que con cualquier cambio en esa clase de bajo nivel afecte
o rompa el funcionamiento de la clase de alto nivel.

**El problema:**

Lenguaje: **Ruby**

```ruby {linenos=table,anchorlinenos=true}
# bad_budgetreport.rb

# Clase de alto nivel - maneja la logica de negocio de reportes
class BudgetReport
  def initialize
    # Aca en esta clase de alto nivel estamos dependiendo
    # de la clase MySQLDatabase la cual es de bajo nivel.
    # incumpliendo asi el principio de inversion de dependencias.
    @database = MySQLDatabase.new
  end

  def open(date)
    puts "Opening report for date #{date}"
  end

  def save
    puts "saving report to database #{@database.class}"
    # usando metodos de la clase de bajo nivel de la cual dependemos.
    @database.insert
  end
end

# clase de bajo nivel
# maneja solamente las conexiones con la DB.
class MySQLDatabase
  # Cualquier cambio en esta clase de bajo nivel podria afectar la clase de
  # alto nivel y romper su funcionamiento.
  def insert
    puts 'inserting data on the MySQL Server'
  end

  def update
    puts 'update data on the MySQL Server'
  end

  def delete
    puts 'deleting data on the MySQL Server'
  end
end

MySQLDatabase.new
report = BudgetReport.new
report.open('06-11-2024')
report.save
``````

Como vemos, nuestra clase `BudgetReport` la cual es de alto nivel, depende de
la clase de bajo nivel `MySQLlDatabase` lo cual incumple el Principio de 
Inversión de Dependencias, ya que si realizamos cambios en `MySQLDatabase`
corremos el riesgo de romper el comportamiento de `BudgetReport`, además 
de que si quisiéramos cambiar la base de datos, tendríamos que modificar
`BudgetReport`.

**La solución:**

Lenguaje: **Ruby**

```ruby {linenos=table,anchorlinenos=true}
# good_budgetreport.rb


# Interfaz - Alto nivel - Abstraccion
#
# Nuestra interfaz Database es de alto nivel
# y especifica los metodos comunes que necesitamos
# en la logina de negocios y que deben implemetar las
# clases de bajo nivel
module Database
  def insert
    raise NotImplementedError, 'implementa el metodo inser'
  end

  def update
    raise NotImplementedError, 'implementa el metodo update'
  end

  def delete
    raise NotImplementedError, 'implementa el metodo delete'
  end
end

# clase - bajo nivel
# Nuestras clases de bajo nivel ahora deben implementar los metodos de la
# interfaz Database
class MySQL
  include Database

  def insert
    puts 'inserting data on the MySQL Server'
  end

  def update
    puts 'update data on the MySQL Server'
  end

  def delete
    puts 'deleting data on the MySQL Server'
  end
end

# clase - bajo nivel
class MongoDB
  include Database

  def insert
    puts 'inserting data on the MongoDB Server'
  end

  def update
    puts 'update data on the MongoDB Server'
  end

  def delete
    puts 'deleting data on the MongoDB Server'
  end
end

# clase - Alto nivel - cliente
#
class BudgetReport
  def initialize(database)
    @database = database
  end

  def open(date)
    puts "Opening report for date #{date}"
  end

  def save
    puts "saving report to database #{@database.class}"
    @database.insert
  end
end

mysqldb = MySQL.new
mongodb = MongoDB.new

report = BudgetReport.new(mysqldb)
report.open('06-11-2024')
report.save

report2 = BudgetReport.new(mongodb)
report2.open('08-11-2024')
report2.save
``````

Con esta abstracción en la que las clases de bajo nivel deben implementar
nuestra interfaz, podemos asegurarnos que al cambiar el código de bajo nivel
no romperemos las funcionalidades de la clase de alto nivel, al no estar
las clases de alto nivel dependen de las clases de bajo nivel. Cumpliendo así
con el principio de inversión de dependencias.

Con un poco de ayuda de inyección de dependencias, podemos integrar nuevas bases
de datos y hacer uso de ellas en el código cliente sin necesidad de modificar
la clase `BudgetReport`.
