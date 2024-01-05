using DataFrames
using JuMP
using GLPKMathProgInterface

function SchedulingSBA()

# Path to the csv files with the preference information
path_faculty = "C:\\Users\\jawad\\Documents\\Work\\Julia\\TestScheduling\\Faculty-Fall2019.csv"
path_sections = "C:\\Users\\jawad\\Documents\\Work\\Julia\\TestScheduling\\Sections-Fall2019.csv"
path_timeslots = "C:\\Users\\jawad\\Documents\\Work\\Julia\\TestScheduling\\TimeSlots-Fall2019.csv"
path_facultysection = "C:\\Users\\jawad\\Documents\\Work\\Julia\\TestScheduling\\FacultySection-Fall2019.csv"
path_facultytimeslot = "C:\\Users\\jawad\\Documents\\Work\\Julia\\TestScheduling\\FacultyTimeSlot-Fall2019.csv"

# Read preferences
Faculty = readtable(path_faculty)
Sections = readtable(path_sections)
TimeSlots = readtable(path_timeslots)
Faculty_Section = readtable(path_facultysection)
Faculty_TimeSlot = readtable(path_facultytimeslot)

# Number of sections, faculty, time_slots, etc
num_faculty = size(Faculty)[1]
num_sections = size(Sections)[1]
num_timeslots = size(TimeSlots)[1]
num_fac_section = size(Faculty_Section)[1]
num_fac_timeslot = size(Faculty_TimeSlot)[1]

# Model and GLPK Solver Declaration
scheduling = Model(solver = GLPKSolverLP())

# Variables
@variable(scheduling, 0 <= assign_faculty_to_section[1:num_fac_section] <= 1)
@variable(scheduling, limit_fac[1:num_faculty] >= 0)
@variable(scheduling, 0 <= assign_faculty_to_timeslot[1:num_fac_timeslot] <= 1)

# Constraints
# Group 1: Each section assigned to exactly one faculty
@constraint(scheduling, each_section_assigned[sec=1:num_sections], sum(assign_faculty_to_section[secfac] for secfac=1:num_fac_section if Faculty_Section[secfac,:ID_Section] == Sections[sec,:Identif]) == 1)
# Group 2: No faculty should exceed its maximum number of Sections
@constraint(scheduling, link_sections_faculty[fac=1:num_faculty], sum(assign_faculty_to_section[secfac] for secfac=1:num_fac_section if Faculty_Section[secfac,:Name_Faculty] == Faculty[fac,:Name]) == limit_fac[fac])
@constraint(scheduling, cannot_exceed_nax_nbr_section_per_faculty[fac=1:num_faculty], limit_fac[fac] <= Faculty[fac,:Max_Nbr_Sections])
# Group 3: Faculty assigned to time slots
@constraint(scheduling, timeslots_assigned_to_faculty[fac=1:num_faculty], sum(assign_faculty_to_timeslot[facts] for facts=1:num_fac_timeslot if Faculty_TimeSlot[facts,:Name_Faculty] == Faculty[fac,:Name]) == limit_fac[fac])
@constraint(scheduling, max_nbr_rooms_not_exceeded[ts=1:num_timeslots], sum(assign_faculty_to_timeslot[facts] for facts=1:num_fac_timeslot if Faculty_TimeSlot[facts,:ID_TimeSlot] == TimeSlots[ts,:Identif]) <= TimeSlots[ts,:Max_Nbr_Rooms_Available])

# Objective: Maximize the sum of the faculty preferences for sections and time slots
@objective(scheduling, Max, sum(Faculty_Section[secfac,:Preference] * assign_faculty_to_section[secfac] for secfac=1:num_fac_section) + sum(Faculty_TimeSlot[facts,:Preference] * assign_faculty_to_timeslot[facts] for facts=1:num_fac_timeslot))

#print(scheduling)

# Solve model
solution = solve(scheduling)

println("Model solved.\r\n")

ParametersFile = open("C:\\Users\\jawad\\Documents\\Work\\Julia\\TestScheduling\\Parameters-Fall2019.txt","w")
ResultsFile = open("C:\\Users\\jawad\\Documents\\Work\\Julia\\TestScheduling\\Results-Fall2019.txt","w")

write(ParametersFile, "----------\r\n")
write(ParametersFile, "PARAMETERS\r\n")
write(ParametersFile, "----------\r\n")

write(ParametersFile, "\r\nFaculty:\r\n")
for i=1:num_faculty
  write(ParametersFile, "Name: ", Faculty[i,:Name], " - Max Number Sections: ", @sprintf("%d", Faculty[i,:Max_Nbr_Sections]), "\r\n")
end

write(ParametersFile, "\r\nSections:\r\n")
for i=1:num_sections
  write(ParametersFile, "ID: ", Sections[i,:Identif], "\r\n")
end

write(ParametersFile, "\r\nTime Slots:\r\n")
for i=1:num_timeslots
  write(ParametersFile, "ID: ", TimeSlots[i,:Identif], " - Max Number Rooms Available: ", @sprintf("%d", TimeSlots[i,:Max_Nbr_Rooms_Available]), "\r\n")
end

write(ParametersFile, "\r\nFaculty Preferences for Sections:\r\n")
for i=1:num_fac_section
  write(ParametersFile, Faculty_Section[i,:Name_Faculty], "'s preference for ", Faculty_Section[i,:ID_Section], ": ", @sprintf("%d", Faculty_Section[i,:Preference]), "\r\n")
end

write(ParametersFile, "\r\nFaculty Preferences for Time Slots:\r\n")
for i=1:num_fac_timeslot
  write(ParametersFile, Faculty_TimeSlot[i,:Name_Faculty], "'s preference for ", Faculty_TimeSlot[i,:ID_TimeSlot], ": ", @sprintf("%d", Faculty_TimeSlot[i,:Preference]), "\r\n")
end

close(ParametersFile)

write(ResultsFile, "-------\r\n")
write(ResultsFile, "RESULTS\r\n")
write(ResultsFile, "-------\r\n")

if solution == :Optimal
  write(ResultsFile, "\r\nSections to Faculty:\r\n")
  for secfac=1:num_fac_section
      if getvalue(assign_faculty_to_section[secfac]) == 1 write(ResultsFile, Faculty_Section[secfac,:ID_Section], " assigned to ", Faculty_Section[secfac,:Name_Faculty], "\r\n")
      end
  end
  write(ResultsFile, "\r\nTime Slots to Faculty:\r\n")
  for facts=1:num_fac_timeslot
      if getvalue(assign_faculty_to_timeslot[facts]) == 1 write(ResultsFile, Faculty_TimeSlot[facts,:ID_TimeSlot], " assigned to ", Faculty_TimeSlot[facts,:Name_Faculty], "\r\n")
      end
  end
else
    write(ResultsFile, "No solution!\r\n")
end

println("Results output to Results.txt.\r\n")

close(ResultsFile)

end;

@time SchedulingSBA()
