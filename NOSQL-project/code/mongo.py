from pymongo import MongoClient
from tkinter import *

myclient = MongoClient()
myclient = MongoClient('localhost', 27017)
database = myclient['BDD']
world = database['world']

def requette1():
    return len(world.distinct("Name"))

def requette2():
    return world.distinct("Continent")
def requette3():
    return world.find_one({"Name":"Algeria"})
def requette4():
    list=[]
    for i in world.find({"Continent":"Africa","Population":{"$lt":100000}}):
        list.append(i["Name"])
    return list
def requette5():
    list=[]
    for i in  world.find({"Continent":"Oceania","IndepYear":{"$ne":"NA"}}):
        list.append(i["Name"])
    return list
def requette6():
    list=[]
    surface=[]
    for i in world.distinct("Continent"):
        list.append(i)
        countsurf = 0
        for j in world.find({"Continent":i}):
            countsurf=countsurf+j["SurfaceArea"]
        surface.append(countsurf)
    return list[surface.index(max(surface))]
def requette7():
    result = []
    for continent in world.distinct("Continent"):
            number_of_countries = world.count({"Continent": continent})
            number_of_independant_countries = world.count({"Continent": continent, "IndepYear": {"$ne": "NA"}})
            population = 0
            for country in world.find({"Continent": continent}):
                population += country["Population"]
            result.append({"Continent": continent, "Nombre de pays": number_of_countries,
                           "Nombre de pays indépendant": number_of_independant_countries,
                           "Population": population})
    return result
def requette8():
    i = world.find_one({"Name":"Algeria"})["Cities"]
    cpt=sum(map(lambda x: int (x['Population']),i))
    return cpt
def requette9():
    capital=world.find_one({"Name":"Algeria"})["Capital"]["Name"]
    population=world.find_one({"Name":"Algeria"})["Capital"]["Population"]
    return capital,population
def requette10():
     listlang=[]
     dict={}
     for i in world.find({}):
       lang=[]
       try:offlang=[l['Language'] for l in i ["OffLang"]]
       except:offlang=[]
       try:notofflang=[l['Language'] for l in i ["NotOffLang"]]
       except:notofflang = []
       lang.extend(offlang)
       lang.extend(notofflang)
       dict[i["Name"]] = lang
       listlang.extend(lang)
     listlang=list(set(listlang))
     langues = []
     for l in listlang :
         cpt=0
         for k,v in dict.items() :
             if l in v:
                 cpt=cpt+1
         if cpt>15:
                 langues.append(l)
     return langues
#print(requette10())
#pour voir les 2 methodes on a basculer de la methode algorithmique à la methode aggregate pour les prochaines requettes
def requette11():
   list=[]
   for i in world.aggregate([{'$addFields': {"cpt": {'$size': {"$ifNull": ["$Cities", []]}}}},
                             {'$match': {"cpt": {'$gt': 100}}},{'$sort': {"cpt": -1}},
                             {'$project': {"_id": "$Name", "Number of Cities": "$cpt"}}]):
       list.append(i)
   return list
def requette12():
    list=[]
    for i in world.aggregate([{'$unwind': "$Cities"}, {'$sort': {"Cities.Population": -1}}, {'$limit': 10},
            {'$sort': {"Cities.Population": 1}},
            {'$project': {"_id": "$Cities.Name", "Pays": "$Name", "Population de la ville ": "$Cities.Population"}}]):
        list.append(i)
    return list

def requette13():
    list = []
    for i in (world.find({"OffLang.Language": {'$eq': "Arabic"}}, {"Name": 1})):
        list.append(i["Name"])
    return list
def requette14():
    list = []
    for i in world.aggregate([{'$addFields': {"i": {'$concatArrays': ["$OffLang", "$NotOffLang"]}}},
            {'$addFields': {"l": {'$size': {"$ifNull": ["$i", []]}}}}, {'$sort': {"l": -1}}, {'$limit': 5},
            {'$group': {"_id": "$Name"}}]):
        list.append(i["_id"])
    return list
def requette15():
    list = []
    for i in world.aggregate([{'$addFields': {"cpt": {'$sum': "$Cities.Population"}}},
                {'$addFields': {"c": {'$cmp': ['$cpt', '$Population']}}},{'$match': {"c": {'$gt': 1}}},
                    {'$project': { "Name": "$Name","Population des villes ": "$cpt","Population :": "$Population"}}]):
        list.append(i["Name"])

    return list


def showSelected(evt):
    selection = evt.widget.curselection()
    index=selection[0]
    if(index==0):
            data = evt.widget.get(index)
            lab.configure(text="1. Déterminer le nombre exact de pays : ")
            print(requette1())
            lb.configure(text=requette1())
    if (index==1):
        data = evt.widget.get(index)
        lab.configure(text="2. Lister les différents continents :  ")
        print(requette2())
        l=requette2()
        #texte.pack(expand=True)
        #for enreg in l:
            #texte.insert('end', enreg+ os.linesep)
        txt=''
        for i in range(len(l)):
            txt=txt+l[i]+'\n'
        lb.configure(text=txt)
    if (index == 2):
        data = evt.widget.get(index)
        lab.configure(text="3. Lister les informations de l’Algérie : ")
        lb.configure(text=requette3())
        print(requette3())
        l=requette3()

        txt = ''
        cpt=0
        for k,v in l.items():
            if(cpt==16):
                txt=txt+k+":"
                cpt2=0
                for i in v:
                    if(cpt2<16):txt = txt +i["Name"]+'-'
                    else:txt = txt +i["Name"]
                    cpt2=cpt2+1
                    if(cpt2==10):txt=txt+'\n'
                txt=txt+'\n'
            else:txt = txt + k + ' : '+str(v)+'\n'
            cpt=cpt+1
        lb.configure(text=txt)

    if (index == 3):
        data = evt.widget.get(index)
        lab.configure(text="4. Lister les pays du continent Africain, ayant une population inférieure à 100000 habitants : ")
        l=requette4()
        print(requette4())
        txt = ''
        for i in range(len(l)):
            txt = txt + l[i] + '\n'
        lb.configure(text=txt)
    if (index == 4):
        data = evt.widget.get(index)
        lab.configure(text="5. Lister les pays indépendant du continent océanique : ")
        l = requette5()
        print(requette5())
        txt = ''
        for i in range(len(l)):
            txt = txt + l[i] + '\n'
        lb.configure(text=txt)
    if (index == 5):
        data = evt.widget.get(index)
        lab.configure(text="6. Quel est le plus gros continent en termes de surface ? (un seul continent affiché à la fin)  ")
        lb.configure(text=requette6())
        print(requette6())
    if (index == 6):
        data = evt.widget.get(index)
        lab.configure(text="7. Donner par continents le nombre de pays, la population totale et en bonus le nombre de pays indépendant : ")
        print(requette7())
        l=requette7()
        txt = ''
        cpt=0
        for i in (l):
            cpt=0
            for v in i.values():
                if(cpt==1):txt =txt+"Nombre de pays :"+ str(v)+" , "
                elif (cpt == 2):txt = txt + "Nombre de pays indépandent :" + str(v)+"\n"
                elif(cpt==3) :txt = txt+"Population : "+ str(v)+"\n"
                else:txt = txt+ str(v)+"\n"
                cpt=cpt+1
        lb.configure(text=txt)
    if (index ==7):
        data = evt.widget.get(index)
        lab.configure(text="8. Donner la population totale des villes d’Algérie :  ")
        print(requette8())
        lb.configure(text=requette8())
    if (index == 8):
        data = evt.widget.get(index)
        lab.configure(text="9. Donner la capitale (uniquement nom de la ville et population) d’Algérie : ")
        l=requette9()
        print(requette9())
        txt="Nom : "+l[0]+'\n' +"Population : "+str(l[1])
        lb.configure(text=txt)
    if (index == 9):
        data = evt.widget.get(index)
        lab.configure(text="10. Quelles sont les langues parlées dans plus de 15 pays ? ")
        print(requette10())
        l=requette10()
        txt=''
        for i in l:
            txt=txt+i+'\n'
        lb.configure(text=txt)
    if (index ==10):
        data = evt.widget.get(index)
        lab.configure(text="11. Calculer pour chaque pays le nombre de villes (pour les pays ayant au moins 100 villes), en les triant par ordre décroissant du nombre de villes :")
        print(requette11())
        l = requette11()
        tst = 'NOMBRE DE VILLES POUR CHAQUE PAYS' + '\n'
        txt = ''
        for i in (l):
            for j in i.values():
                txt = txt + str(j) + ' '
            txt = txt + '\n'
        txt = tst + txt
        lb.configure(text=txt)
    if (index == 11):
        data = evt.widget.get(index)
        lab.configure(text="12. Lister les 10 villes les plus habitées, ainsi que leur pays, dans l’ordre décroissant de la population : ")
        print(requette12())
        l=requette12()
        tst='VILLE---PAYS---POPULATION '+ '\n'
        txt = ''
        for i in (l):
            cpt = 0
            for j in i.values():

                if(cpt<2):txt = txt + str(j)+'--'
                else:txt = txt + str(j)
                cpt=cpt+1
            txt=txt+ '\n'
        txt=tst+txt
        lb.configure(text=txt)
    if (index == 12):
        data = evt.widget.get(index)
        lab.configure(text="13. Lister les pays pour lesquels l’Arabe est une langue officielle : ")
        print(requette13())
        l=requette13()
        txt = ''
        for i in l:
            txt=txt+i+'\n'
        lb.configure(text=txt)
    if (index ==13):
        data = evt.widget.get(index)
        lab.configure(text="14. Lister les 5 pays avec le plus de langues parlées :")
        print(requette14())
        l=requette14()
        txt = ''
        for i in l:
            txt = txt + i + '\n'
        lb.configure(text=txt)
    if (index == 14):
        data = evt.widget.get(index)
        lab.configure(text="15. Lister les pays pour lesquels la somme des populations des villes est supérieure à la population du pays :")
        print(requette15())
        if (not requette15()): lb.configure(text="Il n'y a pas de pays pour lesquels la somme des populations des villes est supérieure à la population du pays ")
window=Tk()
window.title("MONGO DB PROJECT")
window.geometry("1080x720")
window.iconbitmap("mongo.ico")
window.config(background='#008080')
label_title=Label(window,text="choisissez la requette que vous souhaitez executer :  ",font=("Courrier",25),bg="#008080")
label_title.pack(pady=50,padx=5)
Lb=Listbox(window , width=25,height=15,bg="#008080",font="bold",relief="sunken",borderwidth=6)
Lb.place(x=50,y=10)
Lb.insert(1,"Requette 1")
Lb.insert(2,"Requette 2")
Lb.insert(3,"Requette 3")
Lb.insert(4,"Requette 4")
Lb.insert(5,"Requette 5")
Lb.insert(6,"Requette 6")
Lb.insert(7,"Requette 7")
Lb.insert(8,"Requette 8")
Lb.insert(9,"Requette 9")
Lb.insert(10,"Requette 10")
Lb.insert(11,"Requette 11")
Lb.insert(12,"Requette 12")
Lb.insert(13,"Requette 13")
Lb.insert(14,"Requette 14")
Lb.insert(15,"Requette 15")
lab =Label(window,font=("Courrier",11),bg="#FFFFFF")
lab.pack(padx=50,pady=10)
Lb.pack(side=LEFT)
Lb.bind('<<ListboxSelect>>',showSelected)
lb = Label(window, font=("Courrier", 11), bg="#FFFFFF")
lb.pack(padx=30, pady=30)
window.mainloop()