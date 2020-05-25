# Dynamic-Bullets
 Yes, very dynamic!
 
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

## License

 This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* My God Dam Determination to getting this thing to work
* My GR 11/12 physics teacher for reminding me about these equations
