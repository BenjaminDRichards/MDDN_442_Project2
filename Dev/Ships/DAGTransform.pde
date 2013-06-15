import java.util.*;

class DAGTransform
// Element in a DAG hierarchy
{
  // Hierarchy data
  private DAGTransform parent;
  private boolean hasParent;
  private ArrayList children;
  
  // Local transform data
  // This is relative to parent
  private PVector localPos;
  private float localRot;
  private PVector localScale;
  
  // World transform data
  // This is relative to origin
  private PVector worldPos;
  private float worldRot;
  private PVector worldScale;
  
  // Animation domain data: optional but necessary for eliminating deep hierarchies of animation drivers
  public boolean useWorldSpace, usePX, usePY, usePZ, useR, useSX, useSY, useSZ;
  
  
  DAGTransform(float wpX, float wpY, float wpZ,
               float wr,
               float wsX, float wsY, float wsZ)
  {
    // Setup hierarchy
    parent = null;
    hasParent = false;
    children = new ArrayList();
    
    // Set world transform
    worldPos = new PVector(wpX, wpY, wpZ);
    worldRot = wr;
    worldScale = new PVector(wsX, wsY, wsZ);
    
    // Setup optional animation domain
    useWorldSpace = false;
    usePX = false;    usePY = false;    usePZ = false;
    useR = false;
    useSX = false;    useSY = false;    useSZ = false;
    
    // Set initial local transform
    updateLocal();
  }
  
  
  public void moveWorld(float x, float y, float z)
  // Move the node in world space
  {
    worldPos.add( new PVector(x, y, z) );
    // Change own local position
    updateLocal();
  }
  // moveWorld
  public void moveWorld(float x, float y)
  // Helper
  {
    moveWorld(x, y, 0);
  }
  // moveWorld
  
  
  public void moveLocal(float x, float y, float z)
  // Move the node in local space
  {
    localPos.add( new PVector(x, y, z) );
    updateWorld();
  }
  // moveLocal
  public void moveLocal(float x, float y)
  // Helper
  {
    moveLocal(x, y, 0);
  }
  // moveLocal
  
  
  public void rotate(float r)
  // Rotate the node by r radians - this affects both world and local space
  {
    worldRot += r;
    updateLocal();
  }
  // rotate
  
  
  public void scale(float x, float y, float z)
  // Scale the node by *xyz - this affects both world and local space
  {
    worldScale.set(worldScale.x * x, worldScale.y * y, worldScale.z * z);
    updateLocal();
  }
  // scale
  public void scale(float s)
  // Helper
  {
    scale(s, s, s);
  }
  // scale
  
  
  public void normalizeRotations()
  // Conform rotations to the 0-TWOPI range
  // This is a direct manipulation; updating children is unnecessary and wasteful.
  {
    localRot = localRot % TWO_PI;
    if(localRot < 0)  localRot += TWO_PI;
    worldRot = worldRot % TWO_PI;
    if(worldRot < 0)  worldRot += TWO_PI;
  }
  // normalizeRotations
  
  
  public void snapTo(DAGTransform d)
  // Orients this node to the world transform of d
  {
    PVector targetPosition = d.getWorldPosition();
    float targetRotation = d.getWorldRotation();
    PVector targetScale = d.getWorldScale();
    setWorldPosition(targetPosition.x, targetPosition.y, targetPosition.z);
    setWorldRotation(targetRotation);
    setWorldScale(targetScale.x, targetScale.y, targetScale.z);
  }
  // snapTo
  
  
  public void setParent(DAGTransform p)
  // Sets up a parent relationship
  {
    if( !p.isChildOf(this) )
    {
      // That is, p isn't already above this node
      // Prevent cycling, this is an acyclic graph
      if(parent != null)
      {
        parent.removeChild(this);
      }
      parent = p;
      hasParent = true;
      
      parent.addChild(this);
      // Update transforms
      updateLocal();
    }
  }
  // setParent
  
  
  public void setParentToWorld()
  // Puts the node into world space
  {
    // Update relationships
    if(parent != null)
    {
      parent.removeChild(this);
    }
    parent = null;
    hasParent = false;
    
    // Update transforms
    updateLocal();
  }
  // setParentToWorld
  
  
  public void addChild(DAGTransform c)
  // Adds a child to the node
  // This shouldn't go recursive more than one loop...
  {
    if( !isChildOf(c) )
    {
      // Prevent cycling
      
      // Add child
      if( !children.contains(c) )
      {
        // That is, it's not already a child
        children.add(c);
        c.updateLocal();
      }
      
      // Ascertain parent relationship
      if( c.getParent() != this )
      {
        // That is, parent isn't set correctly
        if( c.getParent() != null )
        {
          c.getParent().removeChild(c);
        }
        c.setParent(this);
      }
    }
  }
  // addChild
  
  
  public void removeChild(DAGTransform c)
  // Removes a child from the node
  {
    children.remove(c);
    c.updateLocal();
  }
  // removeChild
  
  
  public DAGTransform getParent()
  // Returns the sole parent of this node
  {
    return( parent );
  }
  // getParent
  
  
  public DAGTransform getGrandparent()
  // Returns the world-parented parent at the top of the tree
  {
    if( !hasParent )
    {
      // This is at the top of the tree
      return( this );
    }
    else
    {
      // Go recursive
      return( parent.getGrandparent() );
    }
  }
  // getGrandparent
  
  
  public boolean isChildOf(DAGTransform dag)
  // Returns true if node "dag" is above this node
  // This also counts grandchildren, etc
  {
    if( parent == null )
    {
      // We've reached the top without finding the node in question
      return( false );
    }
    
    else if( parent == dag )
    {
      // We've found the node we're looking for
      return( true );
    }
    
    else
    {
      // Check the parent
      // Recursion!
      return( parent.isChildOf(dag) );
    }
  }
  // isChildOf
  
  
  public void updateLocal()
  // Updates local transforms based on current world transform and hierarchy
  {
    // Get world transforms of parent
    PVector pwPos = new PVector(0,0,0);
    float pwRot = 0;
    PVector pwScale = new PVector(1,1,1);
    if( parent != null )
    {
      pwPos = parent.getWorldPosition();
      pwRot = parent.getWorldRotation();
      pwScale = parent.getWorldScale();
    }
    
    // Subtract parent world from this world
    PVector tempPos = PVector.sub(worldPos, pwPos);
    float tempPosX = tempPos.x;
    float tempPosY = tempPos.y;
    float tempPosZ = tempPos.z;
    
    // Unrotate
    float theta = atan2(tempPosY, tempPosX)  -  pwRot;
    float len = sqrt(tempPosX * tempPosX + tempPosY * tempPosY);
    tempPosX = len * cos(theta);
    tempPosY = len * sin(theta);
    // Recompile
    tempPos.set(tempPosX, tempPosY, tempPos.z);
    
    // Unscale
    tempPos.set( tempPos.x / pwScale.x,  tempPos.y / pwScale.y,  tempPos.z / pwScale.z);
    
    // Set local transforms
    // Set position
    localPos = tempPos;
    // Set rotations
    localRot = worldRot - pwRot;
    // Set scale
    localScale = new PVector( worldScale.x / pwScale.x,  worldScale.y / pwScale.y,  worldScale.z / pwScale.z );
    
    
    // Update children world transforms
    // Local transforms are always preserved
    Iterator i = children.iterator();
    while( i.hasNext() )
    {
      DAGTransform c = (DAGTransform) i.next();
      c.updateWorld();
    }
  }
  // updateLocal()
  
  
  public void updateWorld()
  // Update world transform from local transform
  {
    // Get world transforms of parent
    PVector pwPos = new PVector(0,0,0);
    float pwRot = 0;
    PVector pwScale = new PVector(1,1,1);
    if( parent != null )
    {
      pwPos = parent.getWorldPosition();
      pwRot = parent.getWorldRotation();
      pwScale = parent.getWorldScale();
    }
    
    // Update rotation
    worldRot = pwRot + localRot;
    
    // Update position
    // This uses only the angles of the parent
    float theta = atan2(localPos.y, localPos.x);
    theta += pwRot;
    float d = localPos.mag();
    // Compute X position
    float tempX = cos(theta) * d * pwScale.x + pwPos.x;
    // Compute Y position
    float tempY = sin(theta) * d * pwScale.y + pwPos.y;
    // Compute Z position
    float tempZ = localPos.z * pwScale.z + pwPos.z;
    // Compile total position
    worldPos.set(tempX, tempY, tempZ);
    
    // Update scale
    worldScale.set( localScale.x * pwScale.x,  localScale.y * pwScale.y,  localScale.z * pwScale.z );
    
    // Update children world transforms
    // Local transforms are always preserved
    Iterator i = children.iterator();
    while( i.hasNext() )
    {
      DAGTransform c = (DAGTransform) i.next();
      c.updateWorld();
    }
  }
  // updateWorld
  
  
  public ArrayList getChildren()
  // Gets the immediate children
  {
    return( children );
  }
  // getChildren
  
  
  public ArrayList getAllChildren()
  // Gets a flat list of all children and sub-children
  {
    ArrayList allChildren = new ArrayList();
    Iterator i = children.iterator();
    while( i.hasNext() )
    {
      DAGTransform d = (DAGTransform) i.next();
      allChildren.add(d);
      // Go recursive
      allChildren.addAll( d.getAllChildren() );
    }
    return( allChildren );
  }
  // getAllChildren
  
  
  public PVector getWorldPosition()  {  return( worldPos );  }
  public float getWorldRotation()  {  return( worldRot );  }
  public PVector getWorldScale()  {  return( worldScale );  }
  
  public void setWorldPosition(float x, float y, float z)
  {
    worldPos.set(x,y,z);
    updateLocal();
  }
  public void setWorldRotation(float r)
  {
    worldRot = r;
    updateLocal();
  }
  public void setWorldScale(float x, float y, float z)
  {
    worldScale.set(x,y,z);
    updateLocal();
  }
  
  public PVector getLocalPosition()  {  return( localPos );  }
  public float getLocalRotation()  {  return( localRot );  }
  public PVector getLocalScale()  {  return( localScale );  }
  
  public void setLocalPosition(float x, float y, float z)
  {
    localPos.set(x,y,z);
    updateWorld();
  }
  public void setLocalRotation(float r)
  {
    localRot = r;
    updateWorld();
  }
  public void setLocalScale(float x, float y, float z)
  {  
    localScale.set(x,y,z);
    updateWorld();
  }
  
  
  // "Get-used" methods used for animation driver nodes
  
  public PVector getUsedPosition()
  // Returns the world or local position
  {
    return( useWorldSpace  ?  getWorldPosition()  :  getLocalPosition() );
  }
  // getUsedPosition
  
  public float getUsedRotation()
  // Returns the appropriate rotation
  {
    return( useWorldSpace  ?  getWorldRotation()  :  getLocalRotation() );
  }
  // getUsedRotation
  
  
  public PVector getUsedScale()
  // Returns the appropriate scale
  {
    return( useWorldSpace  ?  getWorldScale()  :  getLocalScale() );
  }
  // getUsedScale
}
// DAGTransform
