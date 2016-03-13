# vehicles = [{name:"Jumper",capacity:9,disponibility:[1,1,1,1,1,1,1,...]},...]
# people = [{name:"Vincent Lecrubier",disponibility:[0,0,0,1,1,1,0,0,0,...],canDrive:["Jumper",...]},...]
# timeSlots = [{date:"Mardi soir",place:"Club"},...]
# Solve people going into vehicles
# result = [{date:"Mardi soir",place:"Club",vehicle:"Jumper",passengers:["Vincent Lecrubier",...]},...]
solve = (vehicles,people,timeSlots) ->
  peopleWaitingToGo=
    ((p.name for p in people when p.disponibility[i]>0.) for t,i in timeSlots)
  vehicleReadyToGo=
    ((v.name for v in vehicles when v.disponibility[i]>0.) for t,i in timeSlots)
  
