Set-PSDebug -Trace 1

Write-Output "listing contents of C drive root"
Get-ChildItem -Path C:\ -Force

Write-Output "listing contents of cwd"
Get-ChildItem -Force

Write-Output 'INFO: Beginning execution'

Write-Output 'INFO: First check if GCP already has python?'
python --version
python.exe --version

# it looks like we can't use the smaller embeddable zip file as it lacks pip
#curl -OutFile python3.7.zip https://www.python.org/ftp/python/3.7.7/python-3.7.7-embed-amd64.zip
#Expand-Archive .\python3.7.zip

Write-Output 'INFO: Downloading python3.7'
curl -OutFile python3.7.exe https://www.python.org/ftp/python/3.7.7/python-3.7.7-amd64.exe

Write-Output 'INFO: Installing python'
New-Item -Path C:\tmp -Type Directory
New-Item -Path C:\tmp\python -Type Directory
.\python3.7.exe /passive TargetDir=C:\tmp\python IncludePip=1

Write-Output 'INFO: Installing pip, setuptools, and virtualenv'
C:\tmp\python\python.exe -m pip install --upgrade --user pip wheel setuptools virtualenv

Write-Output 'INFO: Installing kivy'
New-Item -Path C:\tmp\kivy_venv -Type Directory
C:\tmp\python\python.exe -m virtualenv C:\tmp\kivy_venv
C:\tmp\kivy_venv\Scripts\activate.ps1
C:\tmp\kivy_venv\Scripts\python.exe -m pip install docutils pygments pypiwin32 kivy_deps.sdl2 kivy_deps.glew kivy_deps.angle
C:\tmp\kivy_venv\Scripts\python.exe -m pip install kivy

Write-Output 'INFO: Prepare our exe'
#C:\tmp\kivy_venv\Scripts\python.exe -m pip install pyinstaller
#New-Item -Path dist -Type Directory
#cd dist
#C:\tmp\kivy_venv\Scripts\python.exe -m PyInstaller --name helloWorld ..\src\main.py

# First let's confirm that we can get the example in the docs to work
#  * https://kivy.org/doc/stable/guide/packaging-windows.html
C:\tmp\kivy_venv\Scripts\python.exe -m pip install kivy_examples
C:\tmp\kivy_venv\Scripts\python.exe -m PyInstaller --name touchtracer C:\tmp\kivy_venv\share\kivy-examples\demo\touchtracer\main.py

# replace spec file
mv touchtracer.spec touchtracer.orig
echo "# -*- mode: python ; coding: utf-8 -*-
from kivy_deps import glew, sdl2

block_cipher = None


a = Analysis(['C:\\tmp\\kivy_venv\\share\\kivy-examples\\demo\\touchtracer\\main.py'],
             pathex=['C:\\Users\\user\\Documents\\build-exaple'],
             binaries=[],
             datas=[],
             hiddenimports=['pkg_resources.py2_warn'],
             hookspath=[],
             runtime_hooks=[],
             excludes=[],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=block_cipher,
             noarchive=False)
pyz = PYZ(a.pure, a.zipped_data,
             cipher=block_cipher)
exe = EXE(pyz,
          a.scripts,
          [],
          exclude_binaries=True,
          name='touchtracer',
          debug=False,
          bootloader_ignore_signals=False,
          strip=False,
          upx=True,
          console=True )
coll = COLLECT(exe, Tree('C:\\tmp\\kivy_venv\\share\\kivy-examples\\demo\\touchtracer\\'),
               a.binaries,
               a.zipfiles,
               a.datas,
               *[Tree(p) for p in (sdl2.dep_bins + glew.dep_bins)],
               strip=False,
               upx=True,
               upx_exclude=[],
               name='touchtracer')
" | tee touchtracer.spec

# build it from the spec file
C:\tmp\kivy_venv\Scripts\python.exe -m PyInstaller --name touchtracer touchtracer.spec
