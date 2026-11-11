// Converti automatiquement depuis hammer/entity/bad/walker/Citron.mt (Motion Twin)
package entity.bad.walker;

import swf.*;
import mtlib.*;
using mtlib.StringExt;
import Data as RootData;
class Citron extends entity.bad.Shooter {

/*------------------------------------------------------------------------
    CONSTRUCTEUR
 ------------------------------------------------------------------------*/
  public function new()  untyped {
    super() ;
    setJumpH(50) ;
    setShoot(3) ;
    initShooter(50, 20) ;
  }


/*------------------------------------------------------------------------
    ATTACHEMENT
 ------------------------------------------------------------------------*/
  public static function attach(g:mode.GameMode,x:Dynamic,y:Dynamic)  untyped {
    var linkage:Dynamic = RootData.LINKAGES[RootData.BAD_CITRON];
    var mc : entity.bad.walker.Citron = (( g.depthMan.attach(linkage,RootData.DP_BADS) ):Dynamic) ;
    mc?.initBad(g,x,y) ;
    return mc ;
  }


/*------------------------------------------------------------------------
    EVENT: TIR
 ------------------------------------------------------------------------*/
  override public function onShoot()  untyped {
    var s:Dynamic = entity.shoot.Zeste.attach(game, x,y) ;
    var target:Dynamic = game?.getOne(RootData.PLAYER) ;
    if ( target?.y<y )
      s?.moveUp(s?.shootSpeed) ;
    else
      s?.moveDown(s?.shootSpeed) ;
  }

}

