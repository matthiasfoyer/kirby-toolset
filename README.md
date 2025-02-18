# Kirby Toolset

Raw project that needs testing. Polishing to come.

## Toolset setup
Add the folder to your bash (or zsh) profile
```bash
export PATH="/path/to/kirby-toolset:$PATH"
```
And refresh 
```
source ~/.bash_profile
```

## Kirby installation
From the folder you want your Kirby site to be installed, run :
```bash
kirby-auto-setup
```
Then enter the name of your project

## Kirby deployment

1. Publish both `-site` and `-content` folder to 2 separate repositories

2. Add your project's staging and production servers in your `~/.ssh/config` file following the following format :
```ssh
Host <project-name-with-domain>-staging
  HostName <server>
  User <username>
  IdentityFile <ssh-key>

Host <project-name-with-domain>-production
  HostName <server>
  User <username>
  IdentityFile <ssh-key>
```
Where `<project-name-with-domain>` is your website domain name **WITH extension**

3. Add SSH connexion between servers and your Github account

On the servers :
```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/<name-of-the-key>
```

Then add the public keys to your Github account.

> [!NOTE]
> Before any further action, make sure your distant servers directories are empty

4. Clone both folders in staging and production servers

Use SSH to log in to your server and clone the repositories into the correct directories:

```bash
ssh <project-name-with-domain>-staging
cd /path/to/your/sites
git clone <repository-url-for-site> site
git clone <repository-url-for-content> content
```

Repeat the same steps for the production server:

```bash
ssh <project-name-with-domain>-production
cd /path/to/your/sites
git clone <repository-url-for-site> site
git clone <repository-url-for-content> content
```

5. On the server, add your ssh github key to the ~/.ssh/config
```
IdentityFile ~/.ssh/<github-key>
```
then `chmod 600 ~/.ssh/config` if the file didn't already exist.

5. Run the deploy script

> [!IMPORTANT]  
> Only works for Infomaniak hosted websites

```bash
kirby-deploy <staging|production> <project-name-with-domain>
```
