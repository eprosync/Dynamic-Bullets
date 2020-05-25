![GitHub issues](https://img.shields.io/github/issues/eprosync/Dynamic-Bullets)
![GitHub](https://img.shields.io/github/license/eprosync/Dynamic-Bullets)

# Dynamic-Bullets
 Yes, very dynamic!
 * I'll make a wiki for all the stuff later on
# This is a work in progress addition to all weapon bases!
 Expect some major bugs and issues!

# How to get this working on your weapon base!
 Since some weapon bases vary on how bullets even functions, I'll let you decide
 Some examples on how to use this properly

 SWB/CW 2.0/FAS 2.0/Cosmic's Weapon Base (Hi Anthony :D)
 
 Using this method allows for better modifications to each individual bullet.
```
hook.Add('DynamicBullets.Fired', 'SWB.Sync', function(bullet)
 if bullet.inflictor.Base == 'swb_base' then
  local self = bullet.inflictor
  bullet:SetDamage(self.DamageMin, self.Damage)
  bullet:SetRange(self.MinRange, self.MaxRange)
  bullet:SetVelocity(self.Velocity or 40000)
  bullet:EnablePenetration(self.CanPenetrate)
  bullet:SetPenetration(self.PenetrativeRange, self.PenStr, PenMod)
  bullet:EnableRicochet(self.CanRicochet)
  bullet:Sync(true) -- Override the fucking attribute sync crap
  return true
 end
end)

if self.DynamicBullets then
 DynamicBullets:FireBullet(self.Owner, self, sp, Dir2)
 continue 
end
```
 If you lazy you can just do this
 However this will increase the networking for each bullet by about 1-2 kb-ish
```
DynamicBullets:FireBullet(self.Owner, self, sp, Dir2, function(bullet)
 bullet:SetDamage(self.DamageMin, self.Damage)
 bullet:SetRange(self.MinRange, self.MaxRange)
 bullet:SetVelocity(self.Velocity or 40000)
 bullet:EnablePenetration(self.CanPenetrate)
 bullet:SetPenetration(self.PenetrativeRange, self.PenStr, PenMod)
 bullet:EnableRicochet(self.CanRicochet)
end)
```
 An example of homing bullets with proximity and other factors affecting the bullet
```
local old_physcalc = bullet.PhysicCalc
function bullet:PhysicCalc()
 local _ents = ents.FindInCone( self.pos, self.vel:GetNormalized(), 500, math.cos( math.rad( 10 ) ) )
 local pl
 table.sort( _ents, function(a, b) return self.pos:DistToSqr(a:GetPos()) < self.pos:DistToSqr(b:GetPos()) end )
 for i=1, #_ents do
  if _ents[i]:IsPlayer() and _ents[i] ~= self.owner and _ents[i]:Alive() then
   pl = _ents[i]
   break
  end
 end
 local acc, displace, newvel, dir = old_physcalc(self)
 if pl then
  local targetpos = (pl:GetPos() + pl:OBBCenter())
  newvel = (newvel*.75) + (targetpos - self.pos):GetNormalized() * ((1/targetpos:Distance(self.pos))*500000)
 end
 return acc, displace, newvel, dir
end
```

## License

 This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* My God Dam Determination to getting this thing to work
* My GR 11/12 physics teacher for reminding me about physics so that I can do this
