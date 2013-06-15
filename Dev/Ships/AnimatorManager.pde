import java.util.*;

class AnimatorManager
// Manages Animator objects, removing them once complete
{
  private ArrayList animators;
  
  AnimatorManager()
  {
    animators = new ArrayList();
  }
  
  
  void run(float tick)
  {
    Iterator i = animators.iterator();
    while( i.hasNext() )
    {
      Animator a = (Animator) i.next();
      a.run(tick);
      // Termination check
      if( a.pleaseRemove )
      {
        i.remove();
      }
    }
  }
  // run
  
  
  void addAnimator(Animator a)
  {
    if( !animators.contains(a) )
    {
      animators.add(a);
    }
  }
  // addAnimator
}
// AnimatorManager
