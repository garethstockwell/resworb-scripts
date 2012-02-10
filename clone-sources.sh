#!/bin/bash

set -e

d=`dirname $0`
. $d/common.sh

qt5hash=$(cat $d/qt5-pinned-hash)
qtcomponentshash=$(cat $d/qt-components-pinned-hash)

echo "Get the sources..."

cd $shared_dir

if [ -e ${qt5_dir} ]; then
    echo "$qt5_dir already exists, you should probably run update-sources.sh"
else
    git clone git@gitorious.org:qt/qt5.git qt5
    cd qt5
    git checkout $qt5hash
    ./init-repository --ssh --module-subset=qtbase,qtxmlpatterns,qtjsbackend,qtscript,qtdeclarative,qtsensors,qtlocation,qt3d,qtimageformats,qtquick1
    (cd qtbase && git fetch http://codereview.qt-project.org/p/qt/qtbase refs/changes/54/15954/1 && git cherry-pick FETCH_HEAD)
    (cd qtquick1 && git fetch http://codereview.qt-project.org/p/qt/qtquick1 refs/changes/81/15981/1 && git cherry-pick FETCH_HEAD)
fi

cd $shared_dir

if [ -e ${qtcomponents_dir} ]; then
    echo "$qtcomponents_dir already exists, you should probably run update-sources.sh"
else
    git clone -b qtquick2 git@gitorious.org:qt-components/qt-components.git qt-components
    cd qt-components
    git checkout $qtcomponentshash
fi

cd $shared_dir

if [ -e ${webkit_dir} ]; then
    echo "$webkit_dir already exists, you should probably run update-sources.sh"
else
    git clone git@gitorious.org:webkit/webkit.git
fi

echo "Done"


