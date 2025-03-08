# Apothecary: Real-Time Nationwide Pharmacy Inventory System

## Proof of Concept

This project is a proof of concept/academic exercise (at most).

Patients frequently have a problem (I've certainly experienced this) where a doctor prescribes a medication, sends the prescription electronically (some are legally _required_ to be sent digitally these days), only to find that the pharmacy doesn't have the medication in stock. For additional legal reasons, the prescription cannot be transferred to another pharmacy, and that pharmacy is unable to search inventories of other pharmacies in the area. Adding insult to injury, the doctor's office staff has no way to search for pharmacies in your area that have the medication in stock either (assuming they even answer the phone when you call), leaving you to call every single one trying to find the one place that's got the stuff you need in stock, then call the doctor's office back, explain the situation to a medical assistant who gets paid $12.50 an hour and hope she cares enough to get the doctor to re-send the prescription to the right place before they close.

Now, **all these pharmacies have internet-connected digital inventory control systems.** (This is how they check insurance coverage to see if they'll get paid, or if they'll have to bill you that insane fee for the medication prescribed.) **There is no reason they cannot send their inventory status to a clearing house to keep all parties apprised in near-real-time.**

And if the data can go to a clearing house, it can be searched.

### Technical Implementation

This app consists of a Rails-based API and a very simplistic frontend to utilzie that API. None of this is built with an eye toward actual deployment or use, so it's all intended to be run locally (for now).

See the subdirectories `api` and `frontend` for specifics on how to get each running.

In terms of order of operations, in order you want:

1. Create the API database and seed it with basic starter data;
1. Get the API itself up and running (see `./api` for more details);
1. Adjust settings in the code/configuration for the frontend to access the API (if needed);
1. Run and access the frontend (see `./frontened`).

