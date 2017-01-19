############################################################
#  THE SONIC PI TECHNO MACHINE -- MADE BY MEHACKIT - 2017  #
############################################################

# SET THE TEMPO OF YOUR LIVE SET HERE
use_bpm 100
use_debug false

# VARIABLES FOR THE INSTRUMENTS AND MIXER - CHANGED VIA OSC
beat1Cutoff = 0
beat1Vol = 1.0
kickToggle = 0
kickVol = 1.0
kickDecay = 1.0
kickRate = 1.0
hihatToggle = 0
hihatVol = 1.0
hihatDecay = 0
hihatRate = 1.0
percToggle = 0
percVol = 1.0
percDecay = 0
drumReverb = 0
lowKill = 0
synthCutoff = 30
synthResonance = 0.5
synthAttack = 0
synthRelease = 0.25
synthReverb = 0.5
synthDistortion = 0.2
synthWaveform = :tb303
synth2Waveform = :saw
synth2Volume = 0
synth2Transpose = 0
nuotit = [:r, :r, :r, :r, :r, :r, :r, :r]
kickSample = :bd_haus
hihatSample = :drum_cymbal_closed
beat1Sample = :loop_amen
kickPattern = [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0]
hihatPattern = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]

with_fx :hpf, cutoff: 0, cutoff_slide: 0.5, amp: 1.5 do |lowKillSwitch|
  
  live_loop :kickdrum do
    with_fx :distortion, mix: 0.2 do
      16.times do
        sample kickSample, amp: kickPattern.ring.tick*kickVol*1.5, rate: kickRate, finish: kickDecay, cutoff: 110 if (kickToggle == 1)
        sleep 0.25
      end
    end
  end
  
  with_fx :reverb, room: 0.0, room_slide: 0.1, mix: 0.0, mix_slide: 0.1 do |drumReverbAmount|
    with_fx :lpf, mix: 1.0, cutoff_slide: 0.25, cutoff: 0 do |c|
      live_loop :beat1, sync: :kickdrum do
        sample beat1Sample, beat_stretch: 2, pan: [-0.55, -0.35, 0, 0.35, 0.55].choose, amp: beat1Vol, slice: pick(16), hpf: 60
        sleep 0.25
      end
      
      live_loop :beat1OSC do
        osc=sync "/drum1"
        if (osc[0] == 0)
          if (osc[1] == 0)
            beat1Cutoff = 0
          elsif (osc[1] == 1)
            beat1Cutoff = 127
          end
        elsif (osc[0] == 1)
          beat1Vol = osc[1]
        end
        control c, cutoff: beat1Cutoff
      end
    end
    
    live_loop :hihat, sync: :kickdrum do
      with_fx :hpf, cutoff: 80 do
        with_fx :distortion do
          16.times do
            sample hihatSample, finish: hihatDecay + rrand(0, 0.09), amp: hihatPattern.ring.tick*hihatVol, rate: hihatRate, cutoff: 120, pan: rrand(-0.5, 0.5) if (hihatToggle == 1)
            sleep 0.25
          end
        end
      end
    end
    
    live_loop :drumReverbOSC do
      osc=sync "/drumreverb"
      drumReverb = osc[0]
      control drumReverbAmount, room: drumReverb, mix: drumReverb/2
    end
  end
  
  with_fx :reverb, room: 0.8, mix: 0.6, amp: 1.5 do
    with_fx :hpf, cutoff: 70 do
      live_loop :perc, sync: :kickdrum do
        use_synth :fm
        if (percVol == 1)
          play nuotit.choose, pan: rrand(-0.8,0.8), amp: percVol, attack: 0.03, divisor: rrand(0.1, 2.4), depth: rrand(1,5), release: percDecay + rrand(0, 0.1) if (percToggle == 1)
        end
        sleep [0.25, 0.75, 1.25].choose
      end
    end
  end
  
  
  live_loop :synth, sync: :kickdrum do
    for i in 0..7
      if (nuotit[i] == 0)
        nuotit[i] = :r
      end
    end
    with_fx :reverb, room: synthReverb do
      with_fx :distortion, mix: 0.5, distort: synthDistortion do
        
        # OSCILLATOR 1
        
        use_synth synthWaveform
        if (synth2Transpose != 0 && synthWaveform == :mod_saw)
          use_synth_defaults mod_range: synth2Transpose, mod_wave: 1
        end
        4.times do |i|
          if (i == 0)
            synthVol = 0.5
          elsif
            synthVol = 1
          end
          use_transpose 0
          
          play nuotit.ring.tick, amp: synthVol, attack: synthAttack, release: synthRelease, cutoff: synthCutoff, res: synthResonance
          
          # OSCILLATOR 2
          
          with_fx :hpf, cutoff: 60 do
            with_fx :lpf, cutoff: 40 + synthCutoff/1.5, res: synthResonance do
              with_synth synth2Waveform do
                use_transpose 0
                use_transpose 12 if one_in(6)
                use_transpose 24 if one_in(12)
                play nuotit.ring.look + synth2Transpose, amp: synth2Volume*synthVol,pan: rrand(-1,1), attack: synthAttack, release: synthRelease if (synth2Volume != 0)
              end
            end
          end
          sleep 0.25
        end
      end
    end
  end
  
  ###############################################
  # LIVE LOOPS HANDLING THE OSC FROM PROCESSING #
  ###############################################
  
  live_loop :kickdrumOSC do
    osc=sync "/drum2"
    if (osc[0] == 0)
      if (osc[1] == 0)
        kickToggle = 0
      elsif (osc[1] == 1)
        kickToggle = 1
      end
    elsif (osc[0] == 1)
      kickVol = osc[1]
    elsif (osc[0] == 2)
      kickDecay = osc[1]
    elsif (osc[0] == 3)
      kickRate = osc[1]
      # KickdrumOSC is receiving and handling the Drum Kit change OSC's as well...
    elsif (osc[0] == 4)
      if (osc[1] == 0)
        beat1Sample = :loop_amen
        kickSample = :bd_haus
        hihatSample = :drum_cymbal_closed
      elsif (osc[1] == 1)
        beat1Sample = :loop_tabla
        kickSample = :bd_sone
        hihatSample = :drum_cymbal_pedal
      elsif (osc[1] == 2)
        beat1Sample = :loop_safari
        kickSample = :bd_fat
        hihatSample = :elec_tick
      elsif (osc[1] == 3)
        beat1Sample = :loop_breakbeat
        kickSample = :bd_tek
        hihatSample = :elec_ping
      end
    end
  end
  
  live_loop :hihatOSC do
    osc=sync "/drum3"
    if (osc[0] == 0)
      if (osc[1] == 0)
        hihatToggle = 0
      elsif (osc[1] == 1)
        hihatToggle = 1
      end
    elsif (osc[0] == 1)
      hihatVol = osc[1]
    elsif (osc[0] == 2)
      hihatDecay = osc[1]
    elsif (osc[0] == 3)
      hihatRate = osc[1]
    end
  end
  
  live_loop :percOSC do
    osc=sync "/drum4"
    if (osc[0] == 0)
      if (osc[1] == 0)
        percToggle = 0
      elsif (osc[1] == 1)
        percToggle = 1
      end
    elsif (osc[0] == 1)
      percVol = osc[1]
    elsif (osc[0] == 2)
      percDecay = osc[1]
    end
  end
  
  live_loop :synthOSC do
    osc=sync "/synth"
    if (osc[0] == 0)
      synthCutoff = osc[1]
    elsif (osc[0] == 1)
      synthResonance = osc[1]
    elsif (osc[0] == 2)
      synthAttack = osc[1]
    elsif (osc[0] == 3)
      synthRelease = osc[1]
    elsif (osc[0] == 4)
      synthReverb = osc[1]
    elsif (osc[0] == 5)
      synthDistortion = osc[1]
    elsif (osc[0] == 6)
      synth2Volume = osc[1]
    elsif (osc[0] == 7)
      synth2Transpose = osc[1]
    end
  end
  
  live_loop :waveform1OSC do
    osc=sync "/waveform1"
    if (osc[0] == 0)
      synthWaveform = :tb303
    elsif (osc[0] == 1)
      synthWaveform = :saw
    elsif (osc[0] == 2)
      synthWaveform = :pulse
    elsif (osc[0] == 3)
      synthWaveform = :mod_saw
    end
  end
  
  live_loop :waveform2OSC do
    osc=sync "/waveform2"
    if (osc[0] == 0)
      synth2Waveform = :saw
    elsif (osc[0] == 1)
      synth2Waveform = :pluck
    elsif (osc[0] == 2)
      synth2Waveform = :pretty_bell
    end
  end
  
  live_loop :drumPatternOSC do
    osc=sync "/pattern"
    if (osc[0] == 0)
      kickPattern = [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0]
      hihatPattern = [rrand(0.6, 0.9), 1, 0.8, 1, 1, 1, rrand(0.6, 0.9), 1, 1, rrand(0.6, 0.9), 1, rrand(0.6, 0.9), 1, 1, 1, 1]
    elsif (osc[0] == 1)
      kickPattern = [1, 0, 0, 0.3, 0, 0.75, 0, 0, 1, 0, 0, 0.2, 1, 0, 0, 0]
      hihatPattern = [0.25, 0.5, 1, 0.5, 0.25, 0.5, 1, 0.5, 0.25, 0.5, 1, 0.5, 0.5, 0.25, 1, rrand(0.6, 1.0)]
    elsif (osc[0] == 2)
      kickPattern = [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0]
      hihatPattern = [0.5, 0.5, 1, 0.45, 0.25, 0.5, rrand(0.7, 1.0), 0.5, 0.25, 0.6, 1, 0.35, 0.25, 1, 0.5, 0.75]
    elsif (osc[0] == 3)
      kickPattern = [1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0.25]
      hihatPattern = [0, rrand(0.5, 0.8), 1, 0, 0.6, 1, 0, rrand(0.5, 0.7), rrand(0.8, 1.0), 0, 0.6, 1, 0, 0.6, 1, 1.2]
    end
  end
  
  live_loop :note1OSC do
    osc1=sync "/note1"
    nuotit[0] = osc1[0]
  end
  live_loop :note2OSC do
    osc2=sync "/note2"
    nuotit[1] = osc2[0]
  end
  live_loop :note3OSC do
    osc3=sync "/note3"
    nuotit[2] = osc3[0]
  end
  live_loop :note4OSC do
    osc4=sync "/note4"
    nuotit[3] = osc4[0]
  end
  live_loop :note5OSC do
    osc5=sync "/note5"
    nuotit[4] = osc5[0]
  end
  live_loop :note6OSC do
    osc6=sync "/note6"
    nuotit[5] = osc6[0]
  end
  live_loop :note7OSC do
    osc7=sync "/note7"
    nuotit[6] = osc7[0]
  end
  live_loop :note8OSC do
    osc8=sync "/note8"
    nuotit[7] = osc8[0]
  end
  live_loop :lowKillOSC do
    osc=sync "/lowkill"
    if (osc[0] == 0)
      lowKill = 0
    elsif (osc[0] == 1)
      lowKill = 60
    end
    control lowKillSwitch, cutoff: lowKill
    puts lowKill
  end
end
