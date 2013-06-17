class StoryEvent
// Event to trigger at a certain time
{
  float triggerTime;
  int commandCode;
  float checkTime, lastCheckTime;
  boolean triggered;
  HashMap extra;
  
  StoryEvent(float triggerTime, int commandCode)
  {
    this.triggerTime = triggerTime;
    this.commandCode = commandCode;
    checkTime = 0;
    lastCheckTime = -1;
    triggered = false;
    extra = new HashMap();
  }
  
  
  boolean isTriggered(float inputTime)
  // Check whether the time has passed over the trigger
  {
    // Update time values
    lastCheckTime = checkTime;
    checkTime = inputTime;
    
    // Check for crossover
    //   by using multiplication method: only one positive and one negative produce negatives
    if( (triggerTime - lastCheckTime) * (triggerTime - checkTime) <= 0 )
    {
      triggered = true;
      return(true);
    }
    else  return(false);
  }
  // isTriggered
  
  
  public void addExtra(String label, Object obj)
  {  extra.put(label, obj);  }
  
  public Object getExtra(String label)
  {  return( extra.get(label) );  }
}
// StoryEvent
