local Cycle={Duration=960,DayDuration=720,StartClock=10.4}
function Cycle.epoch(now)return now-(Cycle.StartClock-6)/12*Cycle.DayDuration end
function Cycle.clock(now,epoch)
 local phase=(now-epoch)%Cycle.Duration
 return (phase<Cycle.DayDuration and 6+phase/Cycle.DayDuration*12 or 18+(phase-Cycle.DayDuration)/(Cycle.Duration-Cycle.DayDuration)*12)%24
end
function Cycle.daylight(clock)
 return math.clamp((math.sin((clock-6)/24*math.pi*2)+.12)/.52,0,1)
end
function Cycle.night(clock)return 1-Cycle.daylight(clock)end
return Cycle
