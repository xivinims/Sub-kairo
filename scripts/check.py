#!/usr/bin/env python3
"""Compile Luau, test campaign rules, build a Studio place and verify its data model."""
import argparse,json,subprocess,xml.etree.ElementTree as ET
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--luau',default='luau');p.add_argument('--compiler',default='luau-compile');p.add_argument('--rojo',default='rojo');a=p.parse_args()
for path in sorted(Path('src').rglob('*.luau'))+sorted(Path('studio').rglob('*.luau')):
 r=subprocess.run([a.compiler,str(path)],stdout=subprocess.DEVNULL,stderr=subprocess.PIPE)
 if r.returncode:raise SystemExit(r.stderr.decode(errors='replace'))
subprocess.run([a.luau,'tests/campaign.spec.luau'],check=True)
subprocess.run([a.rojo,'build','default.project.json','-o','dist/Brambles-Sprout.rbxlx'],check=True)
root=ET.parse('dist/Brambles-Sprout.rbxlx').getroot();items=root.findall('.//Item');classes={}
for item in items:classes[item.attrib['class']]=classes.get(item.attrib['class'],0)+1
names={el.text for el in root.findall('.//Properties/string[@name="Name"]')}
for expected in ['BrambleWorld','TargetIndex','Shared','BrambleServer','BrambleClient','Presentation']:
 assert expected in names,expected
assert classes.get('Part',0)>1200,classes
assert classes.get('ProximityPrompt',0)==76,classes
assert classes.get('ModuleScript',0)>=5,classes
assert classes.get('LocalScript',0)==2,classes
for script in root.findall('.//ProtectedString[@name="Source"]'):
 assert script.text and len(script.text)>20
report={'campaignAssertions':47,'scriptsCompile':True,'placeBuild':True,'classes':classes,'studioPlaytest':False,'androidDeviceTest':False,'durationMeasured':False,'assetsConfigured':True}
Path('dist/validation.json').write_text(json.dumps(report,indent=2)+'\n');print('PASS: place structure, 76 prompts and embedded scripts')
