// Converti automatiquement depuis hammer/entity/bad/walker/Cerise.mt (Motion Twin)
package entity.bad.walker;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Cerise extends entity.bad.Walker {

/*------------------------------------------------------------------------
    CONSTRUCTEUR
 ------------------------------------------------------------------------*/
  public function new()  untyped {
    super() ;
    animFactor = 0.65 ;
  }


/*------------------------------------------------------------------------
    ATTACHEMENT
 ------------------------------------------------------------------------*/
  public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
    var linkage:Dynamic = RootData.LINKAGES[RootData.BAD_CERISE];
    var mc : entity.bad.walker.Cerise = (( g.depthMan.attach(linkage,RootData.DP_BADS) ):Dynamic) ;
    mc?.initBad(g,x,y) ;
    return mc ;
  }

}

