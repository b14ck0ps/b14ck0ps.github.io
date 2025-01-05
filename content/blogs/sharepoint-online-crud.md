---
date: '2025-01-05T22:26:23+06:00'
draft: false
title: 'A Full CRUD for SharePoint Online with .NET 8'
author: "Ajran Hossain"
tags:
  - SharePoint
  - .NET
  - PnP Framework 
image: /images/blogs/sharepoint-online-crud/SPCRUDCover.svg
description: "Learn how to perform CRUD operations on SharePoint Online using .NET 8 and the PnP Framework."
---
# A Full CRUD for SharePoint Online with .NET 8

This blog is a short and simple tutorial to help you work with SharePoint Online using [.NET 8](https://dotnet.microsoft.com/en-us/download/dotnet/8.0) and the [PnP Framework](https://pnp.github.io/pnpframework/). While doing some R&D, I decided to document this process in case it helps someone.

---

## Prerequisites

Before starting, ensure you have:
1. User Credentials: A user account with access to the SharePoint Online site.
2. Make sure this account **must not have MFA enabled**. If I discover a workaround for this, I will update the blog.
3. Development Environment: .NET 8 installed on your machine.

---

## Step 1: Configure an Application in Azure Active Directory (AAD) 
[Ref: mslearn](https://learn.microsoft.com/en-us/sharepoint/dev/sp-add-ins/using-csom-for-dotnet-standard#configuring-an-application-in-azure-ad)

To interact with SharePoint Online, you need to create and configure an application in Azure AD. Here’s how:

1. Go to the [Azure AD Portal](https://aad.portal.azure.com).
2. Select **Azure Active Directory** > **App registrations** > **New registration**.
3. Enter a name for your application and click **Register**.
4. Go to **API Permissions** and add permissions for SharePoint:
   - Choose **Delegated Permissions** and select permissions like `AllSites.Manage`.
5. Grant admin consent to the application’s requested permissions.
6. Go to **Authentication** and enable “Allow public client flows” by setting it to **Yes**.
7. Copy the **Application (client) ID** from the **Overview** page for later use.

---

## Step 2: Create a .NET Console Application

Let’s start by creating a .NET console app:

```bash
dotnet new console -n sp-online-crud
```

Add the required NuGet packages:
```bash
dotnet add package Microsoft.SharePointOnline.CSOM --version 16.1.25611.12000
dotnet add package PnP.Framework --version 1.17.0
```
---

## Step 3: Code

Below is the complete example code for performing CRUD operations on SharePoint lists. Follow along step by step.

```csharp
using System;
using System.Security;
using Microsoft.SharePoint.Client;
using PnP.Framework;

internal class Program
{
    public static void Main(string[] args)
    {
        string client_id = "<YOUR_CLIENT_ID>"; // Replace with your Azure App ID
        string site = "<YOUR_SITE_URL>";      // Replace with your SharePoint site URL
        string user = "<YOUR_USER_EMAIL>";   // Replace with your user email
        SecureString password = GetSecureString("<YOUR_PASSWORD>"); // Replace with your password

        using var authenticationManager = new AuthenticationManager(client_id, user, password);
        using var context = authenticationManager.GetContext(site);

        Console.WriteLine("Retrieving all lists...");
        ShowAllLists(context);

        string listTitle = "<YOUR_LIST_TITLE>"; // Replace with your list title

        Console.WriteLine($"\nReading items from '{listTitle}'...");
        ReadListItems(context, listTitle);

        Console.WriteLine($"\nCreating an item in '{listTitle}'...");
        CreateListItem(context, listTitle, "Ajran");

        Console.WriteLine($"\nUpdating an item in '{listTitle}'...");
        UpdateListItem(context, listTitle, 1, "Ajran Hossain");

        Console.WriteLine($"\nDeleting an item from '{listTitle}'...");
        DeleteListItem(context, listTitle, 1);

        Console.WriteLine("\nOperations completed.");
    }
    }

    private static SecureString GetSecureString(string password)
    {
        var secureString = new SecureString();
        foreach (char c in password)
        {
            secureString.AppendChar(c);
        }
        return secureString;
    }

    private static void ShowAllLists(ClientContext context)
    {
        var lists = context.Web.Lists;
        context.Load(lists, l => l.Include(list => list.Title, list => list.Id));
        context.ExecuteQuery();

        foreach (var list in lists)
        {
            Console.WriteLine($"List Title: {list.Title}, List ID: {list.Id}");
        }
    }

    private static void CreateListItem(ClientContext context, string listTitle, string title)
    {
        try
        {
            var list = context.Web.Lists.GetByTitle(listTitle);
            var itemCreateInfo = new ListItemCreationInformation();
            var newItem = list.AddItem(itemCreateInfo);
            newItem["Title"] = title;
            newItem.Update();
            context.ExecuteQuery();
            Console.WriteLine($"Item '{title}' created successfully.");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error creating item in list '{listTitle}': {ex.Message}");
        }
    }

    private static void ReadListItems(ClientContext context, string listTitle)
    {
        try
        {
            var list = context.Web.Lists.GetByTitle(listTitle);
            var items = list.GetItems(CamlQuery.CreateAllItemsQuery());
            context.Load(items);
            context.ExecuteQuery();

            Console.WriteLine($"Items in '{listTitle}':");
            foreach (var item in items)
            {
                Console.WriteLine($"Item ID: {item.Id}, Title: {item["Title"]}");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error reading items from list '{listTitle}': {ex.Message}");
        }
    }
     private static void UpdateListItem(ClientContext context, string listTitle, int itemId, string newTitle)
    {
        try
        {
            var list = context.Web.Lists.GetByTitle(listTitle);
            var item = list.GetItemById(itemId);
            item["Title"] = newTitle;
            item.Update();
            context.ExecuteQuery();
            Console.WriteLine($"Item with ID {itemId} updated successfully to '{newTitle}'.");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error updating item in list '{listTitle}': {ex.Message}");
        }
    }

    private static void DeleteListItem(ClientContext context, string listTitle, int itemId)
    {
        try
        {
            var list = context.Web.Lists.GetByTitle(listTitle);
            var item = list.GetItemById(itemId);
            item.DeleteObject();
            context.ExecuteQuery();
            Console.WriteLine($"Item with ID {itemId} deleted successfully.");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error deleting item from list '{listTitle}': {ex.Message}");
        }
    }
}
```

---

**List Operations**:
   - **Retrieve All Lists**: Fetches and displays all lists in the site.
   - **Read Items**: Retrieves and displays items from a specific list.
   - **Create Items**: Adds a new item to a specified list.

You can extend the code further to include update and delete operations by following similar patterns.

Happy coding! 🚀

