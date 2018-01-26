# What is Infrastructure as Code

You've come a long way going through all the labs and learning about different Infrastructure as Code tools. Some sort of presentation of what Infrastructure as Code is should already be shaped in your head.

To conclude this tutorial, I summarize some of the key points about what Infrastructure as Code means.

1. `We use code to describe infrastructure`. We don't use UI to launch a VM, we decribe its desired characteristics in code and tell the tool to do that.
2. `Everyone is using the same tested code for infrastructure management operations and not creating its own implementation each time`. We talked about it when discussing downsides of scripts. Common infrastructure management operations should rely on tested code functions which are used in the team. It makes everyday operations more time efficient and less error-prone.
3. `Automated operations`. We don't run commands ourselves to lauch and configure a system, but instead use a configuration syntax provided by IaC tool to tell it what should be done.
4. `We apply software development practices to infrastructure`. In software development, practices like keeping code in source control or peer reviews are very common. They make development reliable and working in a team possible. Since our infrastructure is described in code, we can apply the same practices to our infrastructure work.

These are the points that I would make for now. If you feel like there is something else to add or change, please feel free to send a pull request :)